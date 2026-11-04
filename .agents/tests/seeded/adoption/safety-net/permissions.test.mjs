import assert from 'node:assert/strict';
import test from 'node:test';
import { createNotebook } from '../notes.mjs';

const member = { id: 'bob', team: 'north', role: 'member' };
const reader = { ...member, role: 'reader' };

test('anonymous people see no notes and cannot write', () => {
  const book = createNotebook();
  assert.deepEqual(book.visible(null), []);
  assert.equal(book.update(null, 'one', 'Changed'), false);
  assert.equal(book.add(null, 'New note'), null);
});

test('members see only their own team', () => {
  assert.deepEqual(createNotebook().visible(member).map(n => n.id), ['one']);
});

test('members cannot change another team\'s note', () => {
  const book = createNotebook();
  assert.equal(book.update(member, 'two', 'Changed'), false);
  assert.equal(book.visible({ ...member, team: 'south' })[0].text, 'Other team');
});

test('readers see their team but cannot add or edit notes', () => {
  const book = createNotebook();
  assert.equal(book.visible(reader).length, 1);
  assert.equal(book.update(reader, 'one', 'Changed'), false);
  assert.equal(book.add(reader, 'New note'), null);
  assert.equal(book.visible(reader)[0].text, 'First note');
});

test('as found: a member can edit a colleague\'s note in the same team', () => {
  const book = createNotebook();
  assert.equal(book.update(member, 'one', 'Changed'), true);
  assert.equal(book.visible(member)[0].text, 'Changed');
});
