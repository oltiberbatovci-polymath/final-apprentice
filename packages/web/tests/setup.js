// Jest setup file for DOM testing
require('@testing-library/jest-dom');

// Mock fetch globally
global.fetch = jest.fn();

// Reset mocks before each test
beforeEach(() => {
  fetch.mockClear();
  document.body.innerHTML = '';
});
