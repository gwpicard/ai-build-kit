# recipe-workflow.rb: run the starter workflow's shell steps and time each one.
require 'yaml'
require 'json'
require 'tmpdir'

workflow, project, selection, report = ARGV
document = YAML.load_file(workflow)
raise 'the project check needs only contents: read' unless document.fetch('permissions') == { 'contents' => 'read' }
job = document.fetch('jobs').fetch('recipe-check')
raise 'unsupported jobs' unless document.fetch('jobs').keys == ['recipe-check']
raise 'unsupported job fields' unless (job.keys - %w[runs-on timeout-minutes env defaults steps]).empty?
raise 'the rehearsal expects bash' unless job.fetch('defaults').fetch('run').fetch('shell') == 'bash'
raise 'unsupported shell defaults' unless job.fetch('defaults') == { 'run' => { 'shell' => 'bash' } }
ids = job.fetch('steps').map { |step| step['id'] }.compact
raise 'step identifiers must be unique' unless ids.uniq == ids
raise 'a selected step does not exist' unless selection == 'all' || (selection.split(',') - ids).empty?
environment = ENV.to_h.merge(job.fetch('env'))
environment['SOURCE_COMMIT'] = 'local-rehearsal'
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
results = []
failed = false
Dir.mktmpdir('recipe-workflow') do |temporary|
  environment['RUNNER_TEMP'] = temporary
  %w[GITHUB_ENV GITHUB_PATH].each do |name|
    environment[name] = File.join(temporary, name)
    File.write(environment[name], '')
  end
  job.fetch('steps').each do |step|
    if step.key?('uses')
      raise 'an action needs a full commit hash' unless step.fetch('uses').match?(/@[0-9a-f]{40}$/)
      puts "Local prerequisite: #{step.fetch('name')} (the GitHub action does not run here)" if selection == 'all'
      next
    end
    raise "unsupported step fields: #{step.keys}" unless (step.keys - %w[name id run if]).empty?
    condition = step['if']
    raise "unsupported condition: #{condition}" if condition && condition != 'always()'
    next unless selection == 'all' || selection.split(',').include?(step.fetch('id'))
    next if failed && condition != 'always()'
    before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    puts "Step: #{step.fetch('name')}"
    $stdout.flush
    ok = system(environment, 'bash', '--noprofile', '--norc', '-eo', 'pipefail', '-c', step.fetch('run'), chdir: project)
    seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - before
    status = ok ? 'pass' : 'fail'
    # GitHub installs the pinned tools before this step, so a mismatch there is a
    # fault. On a maintainer's computer the step can only report the local tools.
    if !ok && step['id'] == 'versions' && ENV['GITHUB_ACTIONS'] != 'true'
      local = %w[node npm supabase].map { |tool| "#{tool} #{`#{tool} --version 2>/dev/null`.lines.first.to_s.strip}" }
      puts "Skipped on this computer: #{step.fetch('name')}. It has #{local.join(', ')}; GitHub installs the pinned versions."
      ok = true
      status = 'skipped'
    end
    puts format('Time: %s | %s | %.3f s', step.fetch('name'), status, seconds)
    results << { id: step.fetch('id'), name: step.fetch('name'), status: status, seconds: seconds }
    failed ||= !ok
    File.readlines(environment.fetch('GITHUB_ENV'), chomp: true).each do |line|
      key, value = line.split('=', 2)
      raise 'unsupported environment file entry' unless value
      environment[key] = value
    end
    extra_paths = File.readlines(environment.fetch('GITHUB_PATH'), chomp: true)
    environment['PATH'] = (extra_paths.reverse + [ENV.fetch('PATH')]).join(File::PATH_SEPARATOR)
  end
end
total = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts format('Total workflow shell time on this computer: %.3f s', total)
File.write(report, JSON.pretty_generate({ steps: results, total: total })) if report
exit(failed ? 1 : 0)
