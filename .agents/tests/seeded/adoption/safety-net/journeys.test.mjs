import assert from 'node:assert/strict';
import test from 'node:test';
import { createNotebook } from '../notes.mjs';

const member = { id: 'bob', team: 'north', role: 'member' };

test('a member adds, reads and edits a note', () => {
  const book = createNotebook();
  const id = book.add(member, 'New note');
  assert.equal(book.visible(member).find(n => n.id === id).text, 'New note');
  assert.equal(book.update(member, id, 'Revised'), true);
  assert.equal(book.visible(member).find(n => n.id === id).text, 'Revised');
});

test('an empty note is refused without changing the list', () => {
  const book = createNotebook();
  assert.equal(book.add(member, '  '), null);
  assert.equal(book.visible(member).length, 1);
});
