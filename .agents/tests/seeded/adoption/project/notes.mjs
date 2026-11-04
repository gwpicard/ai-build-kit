export function createNotebook() {
  const notes = [
    { id: 'one', team: 'north', author: 'alice', text: 'First note' },
    { id: 'two', team: 'south', author: 'sam', text: 'Other team' },
  ];

  function visible(user) {
    if (!user) return [];
    return notes.filter(note => note.team === user.team);
  }

  function update(user, id, text) {
    const note = visible(user).find(note => note.id === id);
    if (!note || user.role === 'reader') return false;
    note.text = text;
    return true;
  }

  function add(user, text) {
    if (!user || user.role === 'reader' || !text.trim()) return null;
    const note = { id: String(notes.length + 1), team: user.team, author: user.id, text };
    notes.push(note);
    return note.id;
  }

  return { visible, update, add };
}
