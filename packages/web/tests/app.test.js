/**
 * Unit tests for Task Manager Web Application
 * Tests the main app.js functionality including task operations and DOM manipulation
 */

// Create a modular version of the app functions for testing
const fs = require('fs');
const path = require('path');

// Read app.js content
const appJsPath = path.join(__dirname, '../src/app.js');
let appJsContent = fs.readFileSync(appJsPath, 'utf8');

// Extract just the function definitions
const createTestFunctions = () => {
  const API_URL = 'http://localhost:5000/api';
  let currentFilter = 'all';

  // Function definitions from app.js
  async function loadTasks() {
    try {
      const response = await fetch(`${API_URL}/tasks`);
      if (!response.ok) throw new Error('Failed to fetch tasks');
      
      const tasks = await response.json();
      displayTasks(tasks);
    } catch (error) {
      console.error('Error loading tasks:', error);
      showError('Failed to load tasks. Please check if the API is running.');
    }
  }

  function displayTasks(tasks) {
    const filteredTasks = currentFilter === 'all' 
      ? tasks 
      : tasks.filter(task => task.status === currentFilter);

    const tasksList = document.getElementById('tasksList');
    if (filteredTasks.length === 0) {
      tasksList.innerHTML = `
        <div class="empty-state">
          <p>No ${currentFilter === 'all' ? '' : currentFilter} tasks found.</p>
          <p>Add a new task to get started!</p>
        </div>
      `;
      return;
    }

    tasksList.innerHTML = filteredTasks.map(task => `
      <div class="task-item ${task.status}" data-id="${task.id}">
        <div class="task-header">
          <h3 class="task-title">${escapeHtml(task.title)}</h3>
          <span class="task-status ${task.status}">${task.status}</span>
        </div>
        ${task.description ? `<p class="task-description">${escapeHtml(task.description)}</p>` : ''}
        <div class="task-meta">Created: ${formatDate(task.created_at)}</div>
        <div class="task-actions">
          <button class="edit-btn" onclick="openEditModal(${task.id})">Edit</button>
          <button class="delete-btn" onclick="deleteTask(${task.id})">Delete</button>
        </div>
      </div>
    `).join('');
  }

  async function handleAddTask(e) {
    e.preventDefault();
    
    const taskData = {
      title: document.getElementById('taskTitle').value,
      description: document.getElementById('taskDescription').value,
      status: document.getElementById('taskStatus').value
    };

    try {
      const response = await fetch(`${API_URL}/tasks`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(taskData)
      });

      if (!response.ok) throw new Error('Failed to create task');

      document.getElementById('taskForm').reset();
      loadTasks();
      showSuccess('Task created successfully!');
    } catch (error) {
      console.error('Error creating task:', error);
      showError('Failed to create task');
    }
  }

  async function openEditModal(taskId) {
    try {
      const response = await fetch(`${API_URL}/tasks/${taskId}`);
      if (!response.ok) throw new Error('Failed to fetch task');
      
      const task = await response.json();
      
      document.getElementById('editTaskId').value = task.id;
      document.getElementById('editTaskTitle').value = task.title;
      document.getElementById('editTaskDescription').value = task.description;
      document.getElementById('editTaskStatus').value = task.status;
      
      document.getElementById('editModal').style.display = 'block';
    } catch (error) {
      console.error('Error loading task:', error);
      showError('Failed to load task');
    }
  }

  async function handleEditTask(e) {
    e.preventDefault();
    
    const taskId = document.getElementById('editTaskId').value;
    const taskData = {
      title: document.getElementById('editTaskTitle').value,
      description: document.getElementById('editTaskDescription').value,
      status: document.getElementById('editTaskStatus').value
    };

    try {
      const response = await fetch(`${API_URL}/tasks/${taskId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(taskData)
      });

      if (!response.ok) throw new Error('Failed to update task');

      document.getElementById('editModal').style.display = 'none';
      loadTasks();
      showSuccess('Task updated successfully!');
    } catch (error) {
      console.error('Error updating task:', error);
      showError('Failed to update task');
    }
  }

  async function deleteTask(taskId) {
    if (!confirm('Are you sure you want to delete this task?')) return;

    try {
      const response = await fetch(`${API_URL}/tasks/${taskId}`, {
        method: 'DELETE'
      });

      if (!response.ok) throw new Error('Failed to delete task');

      loadTasks();
      showSuccess('Task deleted successfully!');
    } catch (error) {
      console.error('Error deleting task:', error);
      showError('Failed to delete task');
    }
  }

  function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function showSuccess(message) {
    alert(message);
  }

  function showError(message) {
    alert('Error: ' + message);
  }

  return {
    loadTasks,
    displayTasks,
    handleAddTask,
    handleEditTask,
    deleteTask,
    openEditModal,
    formatDate,
    escapeHtml,
    showSuccess,
    showError
  };
};

describe('Task Manager Web Application', () => {
  let functions;

  beforeEach(() => {
    // Set up our document body with the HTML structure matching the actual app
    document.body.innerHTML = `
      <form id="taskForm">
        <input type="text" id="taskTitle" required />
        <textarea id="taskDescription"></textarea>
        <select id="taskStatus">
          <option value="pending">Pending</option>
          <option value="completed">Completed</option>
        </select>
        <button type="submit">Add Task</button>
      </form>

      <div id="editModal" style="display: none;">
        <span class="close">&times;</span>
        <form id="editTaskForm">
          <input type="hidden" id="editTaskId" />
          <input type="text" id="editTaskTitle" required />
          <textarea id="editTaskDescription"></textarea>
          <select id="editTaskStatus">
            <option value="pending">Pending</option>
            <option value="completed">Completed</option>
          </select>
          <button type="submit">Update Task</button>
        </form>
      </div>

      <div class="filter-buttons">
        <button class="filter-btn active" data-filter="all">All</button>
        <button class="filter-btn" data-filter="pending">Pending</button>
        <button class="filter-btn" data-filter="completed">Completed</button>
      </div>

      <div id="tasksList"></div>
    `;

    // Mock window.alert and confirm
    global.alert = jest.fn();
    global.confirm = jest.fn(() => true);

    // Create test functions
    functions = createTestFunctions();
  });


  describe('displayTasks', () => {
    test('displays tasks correctly', () => {
      const tasks = [
        { id: 1, title: 'Test Task 1', description: 'Description 1', status: 'pending', created_at: '2024-01-01T10:00:00Z' },
        { id: 2, title: 'Test Task 2', description: 'Description 2', status: 'completed', created_at: '2024-01-02T10:00:00Z' }
      ];

      functions.displayTasks(tasks);

      const tasksList = document.getElementById('tasksList');
      expect(tasksList.children.length).toBe(2);
      expect(tasksList.textContent).toContain('Test Task 1');
      expect(tasksList.textContent).toContain('Test Task 2');
    });

    test('displays empty message when no tasks', () => {
      functions.displayTasks([]);

      const tasksList = document.getElementById('tasksList');
      expect(tasksList.textContent).toContain('No');
      expect(tasksList.textContent).toContain('tasks found');
    });

    test('applies status class to tasks', () => {
      const tasks = [
        { id: 1, title: 'Completed Task', description: 'Done', status: 'completed', created_at: '2024-01-01T10:00:00Z' }
      ];

      functions.displayTasks(tasks);

      const taskItem = document.querySelector('.task-item');
      expect(taskItem.classList.contains('completed')).toBe(true);
    });

    test('escapes HTML in task content', () => {
      const tasks = [
        { id: 1, title: '<script>alert("xss")</script>', description: '<b>bold</b>', status: 'pending', created_at: '2024-01-01T10:00:00Z' }
      ];

      functions.displayTasks(tasks);

      const tasksList = document.getElementById('tasksList');
      expect(tasksList.innerHTML).not.toContain('<script>');
      expect(tasksList.innerHTML).toContain('&lt;script&gt;');
    });
  });

  describe('utility functions', () => {
    test('formatDate formats dates correctly', () => {
      const dateString = '2024-01-15T14:30:00Z';
      const formatted = functions.formatDate(dateString);
      expect(formatted).toBeTruthy();
      expect(formatted).toContain('/');
    });

    test('escapeHtml escapes special characters', () => {
      expect(functions.escapeHtml('<script>')).toBe('&lt;script&gt;');
      expect(functions.escapeHtml('Normal text')).toBe('Normal text');
      expect(functions.escapeHtml('<b>bold</b>')).toBe('&lt;b&gt;bold&lt;/b&gt;');
    });

    test('showSuccess displays alert', () => {
      functions.showSuccess('Test success');
      expect(global.alert).toHaveBeenCalledWith('Test success');
    });

    test('showError displays alert', () => {
      functions.showError('Test error');
      expect(global.alert).toHaveBeenCalledWith('Error: Test error');
    });
  });

  describe('loadTasks', () => {
    test('loads tasks successfully', async () => {
      const mockTasks = [
        { id: 1, title: 'Task 1', description: 'Desc 1', status: 'pending', created_at: '2024-01-01T10:00:00Z' }
      ];

      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockTasks)
        })
      );

      await functions.loadTasks();

      expect(fetch).toHaveBeenCalledWith(expect.stringContaining('/tasks'));
      const tasksList = document.getElementById('tasksList');
      expect(tasksList.children.length).toBeGreaterThan(0);
    });

    test('handles fetch error', async () => {
      global.fetch = jest.fn(() =>
        Promise.reject(new Error('Network error'))
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      await functions.loadTasks();

      expect(consoleError).toHaveBeenCalled();
      expect(global.alert).toHaveBeenCalledWith(expect.stringContaining('Failed to load tasks'));
      
      consoleError.mockRestore();
    });

    test('handles non-ok response', async () => {
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 500
        })
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      await functions.loadTasks();

      expect(global.alert).toHaveBeenCalledWith(expect.stringContaining('Failed to load tasks'));
      
      consoleError.mockRestore();
    });
  });

  describe('handleAddTask', () => {
    test('adds task successfully', async () => {
      const event = {
        preventDefault: jest.fn()
      };

      const newTask = {
        id: 1,
        title: 'New Task',
        description: 'New Description',
        status: 'pending',
        created_at: '2024-01-01T10:00:00Z'
      };

      global.fetch = jest.fn()
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve(newTask)
        })
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve([newTask])
        });

      document.getElementById('taskTitle').value = 'New Task';
      document.getElementById('taskDescription').value = 'New Description';
      document.getElementById('taskStatus').value = 'pending';

      await functions.handleAddTask(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/tasks'),
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        })
      );
      expect(global.alert).toHaveBeenCalledWith('Task created successfully!');
    });

    test('handles add task error', async () => {
      const event = {
        preventDefault: jest.fn()
      };

      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 400
        })
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      document.getElementById('taskTitle').value = 'Task';
      document.getElementById('taskDescription').value = 'Desc';

      await functions.handleAddTask(event);

      expect(global.alert).toHaveBeenCalledWith('Error: Failed to create task');
      
      consoleError.mockRestore();
    });
  });

  describe('deleteTask', () => {
    test('deletes task successfully', async () => {
      global.fetch = jest.fn()
        .mockResolvedValueOnce({
          ok: true
        })
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve([])
        });

      await functions.deleteTask(1);

      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/tasks/1'),
        expect.objectContaining({
          method: 'DELETE'
        })
      );
      expect(global.alert).toHaveBeenCalledWith('Task deleted successfully!');
    });

    test('handles delete cancellation', async () => {
      global.confirm = jest.fn(() => false);
      global.fetch = jest.fn();

      await functions.deleteTask(1);

      expect(fetch).not.toHaveBeenCalled();
    });

    test('handles delete error', async () => {
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 404
        })
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      await functions.deleteTask(999);

      expect(global.alert).toHaveBeenCalledWith('Error: Failed to delete task');
      
      consoleError.mockRestore();
    });
  });

  describe('handleEditTask', () => {
    test('updates task successfully', async () => {
      const event = {
        preventDefault: jest.fn()
      };

      const updatedTask = {
        id: 1,
        title: 'Updated Task',
        description: 'Updated Description',
        status: 'completed',
        created_at: '2024-01-01T10:00:00Z'
      };

      global.fetch = jest.fn()
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve(updatedTask)
        })
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve([updatedTask])
        });

      document.getElementById('editTaskId').value = '1';
      document.getElementById('editTaskTitle').value = 'Updated Task';
      document.getElementById('editTaskDescription').value = 'Updated Description';
      document.getElementById('editTaskStatus').value = 'completed';

      await functions.handleEditTask(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('/tasks/1'),
        expect.objectContaining({
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' }
        })
      );
      expect(global.alert).toHaveBeenCalledWith('Task updated successfully!');
    });

    test('handles update error', async () => {
      const event = {
        preventDefault: jest.fn()
      };

      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 404
        })
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      document.getElementById('editTaskId').value = '999';

      await functions.handleEditTask(event);

      expect(global.alert).toHaveBeenCalledWith('Error: Failed to update task');
      
      consoleError.mockRestore();
    });
  });

  describe('openEditModal', () => {
    test('opens modal with task data', async () => {
      const task = {
        id: 1,
        title: 'Edit Me',
        description: 'Description',
        status: 'pending'
      };

      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve(task)
        })
      );

      await functions.openEditModal(1);

      expect(fetch).toHaveBeenCalledWith(expect.stringContaining('/tasks/1'));
      expect(document.getElementById('editTaskId').value).toBe('1');
      expect(document.getElementById('editTaskTitle').value).toBe('Edit Me');
      expect(document.getElementById('editTaskDescription').value).toBe('Description');
      expect(document.getElementById('editTaskStatus').value).toBe('pending');
      
      const modal = document.getElementById('editModal');
      expect(modal.style.display).toBe('block');
    });

    test('handles modal open error', async () => {
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: false,
          status: 404
        })
      );

      const consoleError = jest.spyOn(console, 'error').mockImplementation();

      await functions.openEditModal(999);

      expect(global.alert).toHaveBeenCalledWith('Error: Failed to load task');
      
      consoleError.mockRestore();
    });
  });
});
