import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

// ── Utility helpers ──────────────────────────────────────────────────────────

function eq(a, b) {
  return a === b;
}

function not(value) {
  return !value;
}

function gt(a, b) {
  return a > b;
}

function formatCurrency(value) {
  if (value == null) return '$0.00';
  return `$${Number(value).toFixed(2)}`;
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function pluralize(count, singular, plural) {
  return count === 1 ? singular : (plural || singular + 's');
}

function classNames(...args) {
  return args.filter(Boolean).join(' ');
}

// ── Constants ────────────────────────────────────────────────────────────────

const STATUS_ACTIVE = 'active';
const STATUS_INACTIVE = 'inactive';
const STATUS_PENDING = 'pending';

const SORT_ASC = 'asc';
const SORT_DESC = 'desc';

const PAGE_SIZE_OPTIONS = [10, 25, 50, 100];
const DEFAULT_PAGE_SIZE = 25;

const COLUMN_DEFINITIONS = [
  { key: 'name', label: 'Name', sortable: true, width: '200px' },
  { key: 'email', label: 'Email', sortable: true, width: '250px' },
  { key: 'status', label: 'Status', sortable: true, width: '120px' },
  { key: 'role', label: 'Role', sortable: true, width: '150px' },
  { key: 'department', label: 'Department', sortable: true, width: '180px' },
  { key: 'salary', label: 'Salary', sortable: true, width: '120px' },
  { key: 'actions', label: 'Actions', sortable: false, width: '100px' },
];

const ROLE_OPTIONS = [
  { value: 'admin', label: 'Administrator' },
  { value: 'manager', label: 'Manager' },
  { value: 'editor', label: 'Editor' },
  { value: 'viewer', label: 'Viewer' },
];

const DEPARTMENT_OPTIONS = [
  { value: 'engineering', label: 'Engineering' },
  { value: 'design', label: 'Design' },
  { value: 'marketing', label: 'Marketing' },
  { value: 'sales', label: 'Sales' },
  { value: 'support', label: 'Support' },
];

const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: 'home' },
  { id: 'users', label: 'Users', icon: 'users' },
  { id: 'settings', label: 'Settings', icon: 'settings' },
  { id: 'reports', label: 'Reports', icon: 'bar-chart' },
];

// ── Template-only components ─────────────────────────────────────────────────

const Spinner = <template>
  <div class="spinner-container {{if @size @size 'medium'}}" ...attributes>
    <div class="spinner" role="status" aria-label="Loading">
      <svg class="spinner-svg" viewBox="0 0 24 24">
        <circle class="spinner-track" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
        <circle class="spinner-head" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
      </svg>
    </div>
    {{#if @label}}
      <span class="spinner-label">{{@label}}</span>
    {{/if}}
  </div>
</template>;

const Badge = <template>
  <span
    class={{classNames
      "badge"
      (if (eq @variant "success") "badge--success")
      (if (eq @variant "error") "badge--error")
      (if (eq @variant "warning") "badge--warning")
      (if (eq @variant "info") "badge--info")
      (if @pill "badge--pill")
    }}
    ...attributes
  >
    {{yield}}
  </span>
</template>;

const EmptyState = <template>
  <div class="empty-state" ...attributes>
    <svg class="empty-state__svg" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5" />
    </svg>
    <h3 class="empty-state__title">{{@title}}</h3>
    {{#if @description}}
      <p class="empty-state__description">{{@description}}</p>
    {{/if}}
    {{#if (has-block)}}
      <div class="empty-state__actions">
        {{yield}}
      </div>
    {{/if}}
  </div>
</template>;

const Card = <template>
  <div
    class={{classNames "card" (if @bordered "card--bordered") (if @compact "card--compact")}}
    ...attributes
  >
    {{#if @header}}
      <div class="card__header">
        <h3 class="card__title">{{@header}}</h3>
      </div>
    {{/if}}
    <div class="card__body">
      {{yield}}
    </div>
    {{#if (has-block "footer")}}
      <div class="card__footer">
        {{yield to="footer"}}
      </div>
    {{/if}}
  </div>
</template>;

const Avatar = <template>
  <div class={{classNames "avatar" (if (eq @size "sm") "avatar--sm")}} ...attributes>
    {{#if @src}}
      <img class="avatar__image" src={{@src}} alt={{@alt}} loading="lazy" />
    {{else}}
      <span class="avatar__initials">{{@initials}}</span>
    {{/if}}
    {{#if @status}}
      <span
        class={{classNames
          "avatar__status"
          (if (eq @status "online") "avatar__status--online")
          (if (eq @status "offline") "avatar__status--offline")
        }}
      ></span>
    {{/if}}
  </div>
</template>;

const IconButton = <template>
  <button
    type="button"
    class={{classNames
      "icon-btn"
      (if (eq @variant "ghost") "icon-btn--ghost")
      (if @danger "icon-btn--danger")
    }}
    disabled={{@disabled}}
    aria-label={{@ariaLabel}}
    ...attributes
  >
    {{yield}}
  </button>
</template>;

const AlertBanner = <template>
  <div
    class={{classNames "alert" (if (eq @type "warning") "alert--warning") (if (eq @type "error") "alert--error")}}
    role="alert"
    ...attributes
  >
    <div class="alert__content">
      <p class="alert__message">{{@message}}</p>
    </div>
    {{#if @dismissible}}
      <button class="alert__dismiss" aria-label="Dismiss" {{on "click" @onDismiss}}>
        <svg aria-hidden="true"><use href="#icon-x" /></svg>
      </button>
    {{/if}}
  </div>
</template>;

const SearchInput = <template>
  <div class="search-input" ...attributes>
    <svg class="search-input__icon" aria-hidden="true"><use href="#icon-search" /></svg>
    <input
      class="search-input__field"
      type="search"
      placeholder={{if @placeholder @placeholder "Search..."}}
      value={{@value}}
      aria-label="Search"
      {{on "input" @onInput}}
      {{on "keydown" @onKeydown}}
    />
    {{#if @value}}
      <button class="search-input__clear" aria-label="Clear search" {{on "click" @onClear}}>
        <svg aria-hidden="true"><use href="#icon-x" /></svg>
      </button>
    {{/if}}
  </div>
</template>;

const StatCard = <template>
  <Card @compact={{true}} @bordered={{true}} ...attributes>
    <div class="stat-card">
      <div class="stat-card__icon stat-card__icon--{{@color}}">
        <svg aria-hidden="true"><use href={{@icon}} /></svg>
      </div>
      <div class="stat-card__content">
        <span class="stat-card__label">{{@label}}</span>
        <span class="stat-card__value">{{@value}}</span>
        {{#if @change}}
          <span class={{classNames "stat-card__change" (if (gt @change 0) "stat-card__change--positive" "stat-card__change--negative")}}>
            {{#if (gt @change 0)}}+{{/if}}{{@change}}%
          </span>
        {{/if}}
      </div>
    </div>
  </Card>
</template>;

// ── Main component ───────────────────────────────────────────────────────────

export default class UserManagementDashboard extends Component {
  @service router;
  @service notifications;

  @tracked searchQuery = '';
  @tracked selectedStatus = null;
  @tracked selectedRole = null;
  @tracked selectedDepartment = null;
  @tracked sortColumn = 'name';
  @tracked sortDirection = SORT_ASC;
  @tracked currentPage = 1;
  @tracked pageSize = DEFAULT_PAGE_SIZE;
  @tracked isLoading = false;
  @tracked showCreateModal = false;
  @tracked showEditModal = false;
  @tracked showDeleteConfirm = false;
  @tracked showFilters = false;
  @tracked selectedUsers = [];
  @tracked editingUser = null;
  @tracked deletingUser = null;
  @tracked activeTab = 'all';
  @tracked sidebarCollapsed = false;

  @tracked formName = '';
  @tracked formEmail = '';
  @tracked formRole = '';
  @tracked formDepartment = '';
  @tracked formSalary = '';
  @tracked formErrors = {};
  @tracked formSubmitting = false;

  get users() {
    return this.args.users || [];
  }

  get filteredUsers() {
    let result = this.users;
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      result = result.filter(
        (u) =>
          u.name.toLowerCase().includes(query) ||
          u.email.toLowerCase().includes(query)
      );
    }
    if (this.selectedStatus) {
      result = result.filter((u) => u.status === this.selectedStatus);
    }
    if (this.selectedRole) {
      result = result.filter((u) => u.role === this.selectedRole);
    }
    if (this.selectedDepartment) {
      result = result.filter((u) => u.department === this.selectedDepartment);
    }
    return result;
  }

  get sortedUsers() {
    return [...this.filteredUsers].sort((a, b) => {
      const valA = a[this.sortColumn];
      const valB = b[this.sortColumn];
      if (valA < valB) return this.sortDirection === SORT_ASC ? -1 : 1;
      if (valA > valB) return this.sortDirection === SORT_ASC ? 1 : -1;
      return 0;
    });
  }

  get paginatedUsers() {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.sortedUsers.slice(start, start + this.pageSize);
  }

  get totalPages() {
    return Math.ceil(this.filteredUsers.length / this.pageSize);
  }

  get allSelected() {
    return this.paginatedUsers.length > 0 &&
      this.paginatedUsers.every((u) => this.selectedUsers.includes(u.id));
  }

  get hasActiveFilters() {
    return !!(this.selectedStatus || this.selectedRole || this.selectedDepartment);
  }

  get totalActiveUsers() {
    return this.users.filter((u) => u.status === STATUS_ACTIVE).length;
  }

  get totalPendingUsers() {
    return this.users.filter((u) => u.status === STATUS_PENDING).length;
  }

  get averageSalary() {
    if (this.users.length === 0) return 0;
    const sum = this.users.reduce((acc, u) => acc + (u.salary || 0), 0);
    return sum / this.users.length;
  }

  get isFormValid() {
    return (
      this.formName.trim().length > 0 &&
      this.formEmail.trim().length > 0 &&
      this.formEmail.includes('@') &&
      this.formRole.length > 0
    );
  }

  @action
  handleSearch(event) {
    this.searchQuery = event.target.value;
    this.currentPage = 1;
  }

  @action
  clearSearch() {
    this.searchQuery = '';
    this.currentPage = 1;
  }

  @action
  handleSearchKeydown(event) {
    if (event.key === 'Escape') {
      this.clearSearch();
    }
  }

  @action
  setStatusFilter(status) {
    this.selectedStatus = this.selectedStatus === status ? null : status;
    this.currentPage = 1;
  }

  @action
  setRoleFilter(event) {
    this.selectedRole = event.target.value || null;
    this.currentPage = 1;
  }

  @action
  setDepartmentFilter(event) {
    this.selectedDepartment = event.target.value || null;
    this.currentPage = 1;
  }

  @action
  clearAllFilters() {
    this.selectedStatus = null;
    this.selectedRole = null;
    this.selectedDepartment = null;
    this.searchQuery = '';
    this.currentPage = 1;
  }

  @action
  toggleFilters() {
    this.showFilters = !this.showFilters;
  }

  @action
  handleSort(column) {
    if (!column.sortable) return;
    if (this.sortColumn === column.key) {
      this.sortDirection = this.sortDirection === SORT_ASC ? SORT_DESC : SORT_ASC;
    } else {
      this.sortColumn = column.key;
      this.sortDirection = SORT_ASC;
    }
  }

  @action
  handlePageChange(page) {
    this.currentPage = page;
  }

  @action
  handlePageSizeChange(event) {
    this.pageSize = Number(event.target.value);
    this.currentPage = 1;
  }

  @action
  toggleSelectAll() {
    if (this.allSelected) {
      this.selectedUsers = [];
    } else {
      this.selectedUsers = this.paginatedUsers.map((u) => u.id);
    }
  }

  @action
  toggleSelectUser(userId) {
    if (this.selectedUsers.includes(userId)) {
      this.selectedUsers = this.selectedUsers.filter((id) => id !== userId);
    } else {
      this.selectedUsers = [...this.selectedUsers, userId];
    }
  }

  @action
  openCreateModal() {
    this.resetForm();
    this.showCreateModal = true;
  }

  @action
  closeCreateModal() {
    this.showCreateModal = false;
    this.resetForm();
  }

  @action
  openEditModal(user) {
    this.editingUser = user;
    this.formName = user.name;
    this.formEmail = user.email;
    this.formRole = user.role;
    this.formDepartment = user.department;
    this.formSalary = String(user.salary || '');
    this.showEditModal = true;
  }

  @action
  closeEditModal() {
    this.showEditModal = false;
    this.editingUser = null;
    this.resetForm();
  }

  @action
  confirmDelete(user) {
    this.deletingUser = user;
    this.showDeleteConfirm = true;
  }

  @action
  cancelDelete() {
    this.showDeleteConfirm = false;
    this.deletingUser = null;
  }

  @action
  async handleDelete() {
    if (!this.deletingUser) return;
    try {
      await this.args.onDeleteUser?.(this.deletingUser.id);
      this.notifications.success(`User "${this.deletingUser.name}" deleted.`);
    } catch (e) {
      this.notifications.error('Failed to delete user.');
    } finally {
      this.showDeleteConfirm = false;
      this.deletingUser = null;
    }
  }

  @action
  async handleCreateSubmit(event) {
    event.preventDefault();
    if (!this.isFormValid) return;
    this.formSubmitting = true;
    try {
      await this.args.onCreateUser?.({
        name: this.formName.trim(),
        email: this.formEmail.trim(),
        role: this.formRole,
        department: this.formDepartment,
        salary: this.formSalary ? Number(this.formSalary) : null,
      });
      this.closeCreateModal();
    } catch (e) {
      this.formErrors = e.errors || {};
    } finally {
      this.formSubmitting = false;
    }
  }

  @action
  async handleEditSubmit(event) {
    event.preventDefault();
    if (!this.isFormValid || !this.editingUser) return;
    this.formSubmitting = true;
    try {
      await this.args.onUpdateUser?.(this.editingUser.id, {
        name: this.formName.trim(),
        email: this.formEmail.trim(),
        role: this.formRole,
        department: this.formDepartment,
        salary: this.formSalary ? Number(this.formSalary) : null,
      });
      this.closeEditModal();
    } catch (e) {
      this.formErrors = e.errors || {};
    } finally {
      this.formSubmitting = false;
    }
  }

  @action
  updateFormField(field, event) {
    this[field] = event.target.value;
  }

  @action
  setActiveTab(tabId) {
    this.activeTab = tabId;
    this.currentPage = 1;
  }

  @action
  toggleSidebar() {
    this.sidebarCollapsed = !this.sidebarCollapsed;
  }

  @action
  async handleRefresh() {
    this.isLoading = true;
    try {
      await this.args.onRefresh?.();
    } finally {
      this.isLoading = false;
    }
  }

  resetForm() {
    this.formName = '';
    this.formEmail = '';
    this.formRole = '';
    this.formDepartment = '';
    this.formSalary = '';
    this.formErrors = {};
    this.formSubmitting = false;
  }

  <template>
    <div class={{classNames "dashboard" (if this.sidebarCollapsed "dashboard--collapsed")}}>
      {{! ── Sidebar ── }}
      <aside class="dashboard__sidebar" aria-label="Main navigation">
        <div class="sidebar__header">
          <span class="sidebar__logo">Acme Corp</span>
          <IconButton @variant="ghost" @ariaLabel="Toggle sidebar" {{on "click" this.toggleSidebar}}>
            <svg aria-hidden="true"><use href="#icon-menu" /></svg>
          </IconButton>
        </div>
        <nav class="sidebar__nav">
          <ul class="sidebar__nav-list" role="menubar">
            {{#each NAV_ITEMS as |navItem|}}
              <li class="sidebar__nav-item" role="none">
                <a
                  class={{classNames "sidebar__nav-link" (if (eq navItem.id "users") "sidebar__nav-link--active")}}
                  href="#"
                  role="menuitem"
                  aria-current={{if (eq navItem.id "users") "page"}}
                >
                  <svg class="sidebar__nav-icon" aria-hidden="true">
                    <use href="#icon-{{navItem.icon}}" />
                  </svg>
                  {{#unless this.sidebarCollapsed}}
                    <span>{{navItem.label}}</span>
                  {{/unless}}
                </a>
              </li>
            {{/each}}
          </ul>
        </nav>
        {{#unless this.sidebarCollapsed}}
          <div class="sidebar__footer">
            <Avatar @initials="JD" @size="sm" @status="online" />
            <div class="sidebar__user-info">
              <span class="sidebar__user-name">Jane Doe</span>
              <span class="sidebar__user-role">Administrator</span>
            </div>
          </div>
        {{/unless}}
      </aside>

      {{! ── Main Content ── }}
      <main class="dashboard__main">
        {{! Page Header }}
        <header class="page-header">
          <div class="page-header__left">
            <h1 class="page-header__title">User Management</h1>
            <p class="page-header__subtitle">Manage your team members and permissions.</p>
          </div>
          <div class="page-header__actions">
            <IconButton
              @variant="ghost"
              @ariaLabel="Refresh"
              @disabled={{this.isLoading}}
              {{on "click" this.handleRefresh}}
            >
              {{#if this.isLoading}}
                <Spinner @size="small" />
              {{else}}
                <svg aria-hidden="true"><use href="#icon-refresh" /></svg>
              {{/if}}
            </IconButton>
            <button class="btn btn--primary" {{on "click" this.openCreateModal}}>
              <svg class="btn__icon" aria-hidden="true"><use href="#icon-plus" /></svg>
              Add User
            </button>
          </div>
        </header>

        {{! Stats }}
        <section class="stats-grid" aria-label="Statistics">
          <StatCard @label="Total Users" @value={{this.users.length}} @icon="#icon-users" @color="blue" @change={{12}} />
          <StatCard @label="Active" @value={{this.totalActiveUsers}} @icon="#icon-check" @color="green" @change={{5}} />
          <StatCard @label="Pending" @value={{this.totalPendingUsers}} @icon="#icon-clock" @color="yellow" @change={{-2}} />
          <StatCard @label="Avg. Salary" @value={{formatCurrency this.averageSalary}} @icon="#icon-dollar" @color="purple" />
        </section>

        {{! Tabs }}
        <div class="tabs" role="tablist" aria-label="User tabs">
          <button
            class={{classNames "tabs__tab" (if (eq this.activeTab "all") "tabs__tab--active")}}
            role="tab"
            aria-selected={{eq this.activeTab "all"}}
            {{on "click" (fn this.setActiveTab "all")}}
          >
            All Users
            <Badge @variant="info" @pill={{true}}>{{this.users.length}}</Badge>
          </button>
          <button
            class={{classNames "tabs__tab" (if (eq this.activeTab "active") "tabs__tab--active")}}
            role="tab"
            aria-selected={{eq this.activeTab "active"}}
            {{on "click" (fn this.setActiveTab "active")}}
          >
            Active
            <Badge @variant="success" @pill={{true}}>{{this.totalActiveUsers}}</Badge>
          </button>
          <button
            class={{classNames "tabs__tab" (if (eq this.activeTab "pending") "tabs__tab--active")}}
            role="tab"
            aria-selected={{eq this.activeTab "pending"}}
            {{on "click" (fn this.setActiveTab "pending")}}
          >
            Pending
            <Badge @variant="warning" @pill={{true}}>{{this.totalPendingUsers}}</Badge>
          </button>
        </div>

        {{! Toolbar }}
        <div class="toolbar">
          <SearchInput
            @value={{this.searchQuery}}
            @placeholder="Search users..."
            @onInput={{this.handleSearch}}
            @onKeydown={{this.handleSearchKeydown}}
            @onClear={{this.clearSearch}}
          />
          <button
            class={{classNames "btn btn--outline" (if this.showFilters "btn--active")}}
            {{on "click" this.toggleFilters}}
          >
            Filters
            {{#if this.hasActiveFilters}}
              <Badge @variant="info" @pill={{true}}>!</Badge>
            {{/if}}
          </button>
          {{#if (gt this.selectedUsers.length 0)}}
            <span class="toolbar__count">
              {{this.selectedUsers.length}} {{pluralize this.selectedUsers.length "user"}} selected
            </span>
          {{/if}}
        </div>

        {{! Filters }}
        {{#if this.showFilters}}
          <Card @bordered={{true}} @compact={{true}}>
            <div class="filter-panel">
              <div class="filter-panel__group">
                <label class="filter-panel__label">Status</label>
                <div class="filter-panel__chips">
                  <button
                    class={{classNames "chip" (if (eq this.selectedStatus STATUS_ACTIVE) "chip--active")}}
                    {{on "click" (fn this.setStatusFilter STATUS_ACTIVE)}}
                  >Active</button>
                  <button
                    class={{classNames "chip" (if (eq this.selectedStatus STATUS_INACTIVE) "chip--active")}}
                    {{on "click" (fn this.setStatusFilter STATUS_INACTIVE)}}
                  >Inactive</button>
                  <button
                    class={{classNames "chip" (if (eq this.selectedStatus STATUS_PENDING) "chip--active")}}
                    {{on "click" (fn this.setStatusFilter STATUS_PENDING)}}
                  >Pending</button>
                </div>
              </div>
              <div class="filter-panel__group">
                <label class="filter-panel__label" for="filter-role">Role</label>
                <select id="filter-role" class="form-select" {{on "change" this.setRoleFilter}}>
                  <option value="">All Roles</option>
                  {{#each ROLE_OPTIONS as |role|}}
                    <option value={{role.value}} selected={{eq this.selectedRole role.value}}>{{role.label}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="filter-panel__group">
                <label class="filter-panel__label" for="filter-dept">Department</label>
                <select id="filter-dept" class="form-select" {{on "change" this.setDepartmentFilter}}>
                  <option value="">All Departments</option>
                  {{#each DEPARTMENT_OPTIONS as |dept|}}
                    <option value={{dept.value}} selected={{eq this.selectedDepartment dept.value}}>{{dept.label}}</option>
                  {{/each}}
                </select>
              </div>
              {{#if this.hasActiveFilters}}
                <button class="btn btn--ghost btn--sm" {{on "click" this.clearAllFilters}}>
                  Clear all
                </button>
              {{/if}}
            </div>
          </Card>
        {{/if}}

        {{! Data Table }}
        <div class="table-container" role="region" aria-label="Users table" tabindex="0">
          {{#if this.isLoading}}
            <div class="table-loading">
              <Spinner @label="Loading users..." />
            </div>
          {{/if}}

          <table class="data-table">
            <caption class="sr-only">
              User management table with {{this.filteredUsers.length}} results
            </caption>
            <thead class="data-table__head">
              <tr>
                <th class="data-table__th" scope="col">
                  <input
                    type="checkbox"
                    checked={{this.allSelected}}
                    aria-label="Select all"
                    {{on "change" this.toggleSelectAll}}
                  />
                </th>
                {{#each COLUMN_DEFINITIONS as |column|}}
                  <th
                    class={{classNames
                      "data-table__th"
                      (if column.sortable "data-table__th--sortable")
                      (if (eq this.sortColumn column.key) "data-table__th--sorted")
                    }}
                    scope="col"
                    style="width: {{column.width}}"
                    aria-sort={{if (eq this.sortColumn column.key) (if (eq this.sortDirection SORT_ASC) "ascending" "descending") "none"}}
                  >
                    {{#if column.sortable}}
                      <button class="data-table__sort-btn" {{on "click" (fn this.handleSort column)}}>
                        {{column.label}}
                        {{#if (eq this.sortColumn column.key)}}
                          <svg class="data-table__sort-icon" aria-hidden="true">
                            {{#if (eq this.sortDirection SORT_ASC)}}
                              <use href="#icon-arrow-up" />
                            {{else}}
                              <use href="#icon-arrow-down" />
                            {{/if}}
                          </svg>
                        {{/if}}
                      </button>
                    {{else}}
                      {{column.label}}
                    {{/if}}
                  </th>
                {{/each}}
              </tr>
            </thead>
            <tbody class="data-table__body">
              {{#if (eq this.paginatedUsers.length 0)}}
                <tr>
                  <td colspan="8" class="data-table__empty">
                    <EmptyState
                      @title="No users found"
                      @description="Try adjusting your filters or add a new user."
                    >
                      {{#if this.hasActiveFilters}}
                        <button class="btn btn--outline btn--sm" {{on "click" this.clearAllFilters}}>
                          Clear Filters
                        </button>
                      {{/if}}
                      <button class="btn btn--primary btn--sm" {{on "click" this.openCreateModal}}>
                        Add User
                      </button>
                    </EmptyState>
                  </td>
                </tr>
              {{else}}
                {{#each this.paginatedUsers as |user|}}
                  <tr class={{classNames "data-table__row" (if (eq user.status STATUS_INACTIVE) "data-table__row--muted")}}>
                    <td class="data-table__td">
                      <input
                        type="checkbox"
                        checked={{this.selectedUsers.includes user.id}}
                        aria-label="Select {{user.name}}"
                        {{on "change" (fn this.toggleSelectUser user.id)}}
                      />
                    </td>
                    <td class="data-table__td">
                      <div class="user-cell">
                        <Avatar
                          @src={{user.avatarUrl}}
                          @initials={{user.initials}}
                          @size="sm"
                          @status={{if (eq user.status STATUS_ACTIVE) "online" "offline"}}
                        />
                        <div class="user-cell__info">
                          <span class="user-cell__name">{{user.name}}</span>
                          {{#if user.title}}
                            <span class="user-cell__title">{{user.title}}</span>
                          {{/if}}
                        </div>
                      </div>
                    </td>
                    <td class="data-table__td">
                      <a href="mailto:{{user.email}}" class="data-table__link">{{user.email}}</a>
                    </td>
                    <td class="data-table__td">
                      <Badge
                        @variant={{if (eq user.status STATUS_ACTIVE) "success"
                          (if (eq user.status STATUS_PENDING) "warning" "error")}}
                        @pill={{true}}
                      >
                        {{capitalize user.status}}
                      </Badge>
                    </td>
                    <td class="data-table__td">{{capitalize user.role}}</td>
                    <td class="data-table__td">{{capitalize user.department}}</td>
                    <td class="data-table__td data-table__td--numeric">
                      {{formatCurrency user.salary}}
                    </td>
                    <td class="data-table__td">
                      <div class="action-btns">
                        <IconButton
                          @variant="ghost"
                          @ariaLabel="Edit {{user.name}}"
                          {{on "click" (fn this.openEditModal user)}}
                        >
                          <svg aria-hidden="true"><use href="#icon-edit" /></svg>
                        </IconButton>
                        <IconButton
                          @variant="ghost"
                          @danger={{true}}
                          @ariaLabel="Delete {{user.name}}"
                          {{on "click" (fn this.confirmDelete user)}}
                        >
                          <svg aria-hidden="true"><use href="#icon-trash" /></svg>
                        </IconButton>
                      </div>
                    </td>
                  </tr>
                {{/each}}
              {{/if}}
            </tbody>
          </table>
        </div>

        {{! Pagination }}
        {{#if (gt this.filteredUsers.length 0)}}
          <nav class="pagination" aria-label="Pagination">
            <span class="pagination__info">
              {{this.filteredUsers.length}} {{pluralize this.filteredUsers.length "result"}}
              — Page {{this.currentPage}} of {{this.totalPages}}
            </span>
            <div class="pagination__controls">
              <button
                class="pagination__btn"
                disabled={{eq this.currentPage 1}}
                aria-label="Previous page"
                {{on "click" (fn this.handlePageChange 1)}}
              >Prev</button>
              <button
                class="pagination__btn"
                disabled={{eq this.currentPage this.totalPages}}
                aria-label="Next page"
                {{on "click" (fn this.handlePageChange this.totalPages)}}
              >Next</button>
            </div>
            <select class="pagination__size" {{on "change" this.handlePageSizeChange}}>
              {{#each PAGE_SIZE_OPTIONS as |size|}}
                <option value={{size}} selected={{eq size this.pageSize}}>{{size}} / page</option>
              {{/each}}
            </select>
          </nav>
        {{/if}}

        {{! Create Modal }}
        {{#if this.showCreateModal}}
          <div class="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="create-title">
            <div class="modal">
              <div class="modal__header">
                <h2 id="create-title" class="modal__title">Create New User</h2>
                <IconButton @variant="ghost" @ariaLabel="Close" {{on "click" this.closeCreateModal}}>
                  <svg aria-hidden="true"><use href="#icon-x" /></svg>
                </IconButton>
              </div>
              <form class="modal__body" {{on "submit" this.handleCreateSubmit}}>
                <div class="form-grid">
                  <div class="form-group">
                    <label class="form-label" for="create-name">Full Name <span class="form-required">*</span></label>
                    <input
                      id="create-name"
                      class={{classNames "form-input" (if this.formErrors.name "form-input--error")}}
                      type="text"
                      placeholder="Enter full name"
                      value={{this.formName}}
                      required
                      {{on "input" (fn this.updateFormField "formName")}}
                    />
                    {{#if this.formErrors.name}}
                      <span class="form-error" role="alert">{{this.formErrors.name}}</span>
                    {{/if}}
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="create-email">Email <span class="form-required">*</span></label>
                    <input
                      id="create-email"
                      class={{classNames "form-input" (if this.formErrors.email "form-input--error")}}
                      type="email"
                      placeholder="user@example.com"
                      value={{this.formEmail}}
                      required
                      {{on "input" (fn this.updateFormField "formEmail")}}
                    />
                    {{#if this.formErrors.email}}
                      <span class="form-error" role="alert">{{this.formErrors.email}}</span>
                    {{/if}}
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="create-role">Role <span class="form-required">*</span></label>
                    <select id="create-role" class="form-select" required {{on "change" (fn this.updateFormField "formRole")}}>
                      <option value="">Select a role</option>
                      {{#each ROLE_OPTIONS as |role|}}
                        <option value={{role.value}} selected={{eq this.formRole role.value}}>{{role.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="create-dept">Department</label>
                    <select id="create-dept" class="form-select" {{on "change" (fn this.updateFormField "formDepartment")}}>
                      <option value="">Select department</option>
                      {{#each DEPARTMENT_OPTIONS as |dept|}}
                        <option value={{dept.value}} selected={{eq this.formDepartment dept.value}}>{{dept.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="create-salary">Salary</label>
                    <input
                      id="create-salary"
                      class="form-input"
                      type="number"
                      min="0"
                      step="1000"
                      value={{this.formSalary}}
                      {{on "input" (fn this.updateFormField "formSalary")}}
                    />
                  </div>
                </div>
                <div class="modal__footer">
                  <button type="button" class="btn btn--secondary" {{on "click" this.closeCreateModal}}>Cancel</button>
                  <button type="submit" class="btn btn--primary" disabled={{not this.isFormValid}}>
                    {{#if this.formSubmitting}}
                      <Spinner @size="small" />
                      Creating...
                    {{else}}
                      Create User
                    {{/if}}
                  </button>
                </div>
              </form>
            </div>
          </div>
        {{/if}}

        {{! Edit Modal }}
        {{#if this.showEditModal}}
          <div class="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="edit-title">
            <div class="modal">
              <div class="modal__header">
                <h2 id="edit-title" class="modal__title">Edit: {{this.editingUser.name}}</h2>
                <IconButton @variant="ghost" @ariaLabel="Close" {{on "click" this.closeEditModal}}>
                  <svg aria-hidden="true"><use href="#icon-x" /></svg>
                </IconButton>
              </div>
              <form class="modal__body" {{on "submit" this.handleEditSubmit}}>
                <div class="form-grid">
                  <div class="form-group">
                    <label class="form-label" for="edit-name">Full Name <span class="form-required">*</span></label>
                    <input
                      id="edit-name"
                      class={{classNames "form-input" (if this.formErrors.name "form-input--error")}}
                      type="text"
                      value={{this.formName}}
                      required
                      {{on "input" (fn this.updateFormField "formName")}}
                    />
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="edit-email">Email <span class="form-required">*</span></label>
                    <input
                      id="edit-email"
                      class={{classNames "form-input" (if this.formErrors.email "form-input--error")}}
                      type="email"
                      value={{this.formEmail}}
                      required
                      {{on "input" (fn this.updateFormField "formEmail")}}
                    />
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="edit-role">Role</label>
                    <select id="edit-role" class="form-select" {{on "change" (fn this.updateFormField "formRole")}}>
                      {{#each ROLE_OPTIONS as |role|}}
                        <option value={{role.value}} selected={{eq this.formRole role.value}}>{{role.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="edit-dept">Department</label>
                    <select id="edit-dept" class="form-select" {{on "change" (fn this.updateFormField "formDepartment")}}>
                      {{#each DEPARTMENT_OPTIONS as |dept|}}
                        <option value={{dept.value}} selected={{eq this.formDepartment dept.value}}>{{dept.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="edit-salary">Salary</label>
                    <input
                      id="edit-salary"
                      class="form-input"
                      type="number"
                      min="0"
                      step="1000"
                      value={{this.formSalary}}
                      {{on "input" (fn this.updateFormField "formSalary")}}
                    />
                  </div>
                </div>
                <div class="modal__footer">
                  <button type="button" class="btn btn--secondary" {{on "click" this.closeEditModal}}>Cancel</button>
                  <button type="submit" class="btn btn--primary" disabled={{not this.isFormValid}}>
                    {{#if this.formSubmitting}}
                      <Spinner @size="small" />
                      Saving...
                    {{else}}
                      Save Changes
                    {{/if}}
                  </button>
                </div>
              </form>
            </div>
          </div>
        {{/if}}

        {{! Delete Confirmation }}
        {{#if this.showDeleteConfirm}}
          <div class="modal-overlay" role="alertdialog" aria-modal="true" aria-labelledby="delete-title">
            <div class="modal modal--sm">
              <div class="modal__header modal__header--danger">
                <h2 id="delete-title" class="modal__title">Delete User</h2>
              </div>
              <div class="modal__body">
                <p>
                  Are you sure you want to delete <strong>{{this.deletingUser.name}}</strong>?
                  This action cannot be undone.
                </p>
                <AlertBanner
                  @type="warning"
                  @message="All associated data will be permanently removed."
                />
              </div>
              <div class="modal__footer">
                <button type="button" class="btn btn--secondary" {{on "click" this.cancelDelete}}>Cancel</button>
                <button type="button" class="btn btn--danger" {{on "click" this.handleDelete}}>
                  Delete User
                </button>
              </div>
            </div>
          </div>
        {{/if}}

        {{! Footer }}
        <footer class="dashboard__footer">
          <span>{{this.filteredUsers.length}} of {{this.users.length}} {{pluralize this.users.length "user"}}</span>
          <span>Acme Corp Admin v2.4.1</span>
        </footer>
      </main>
    </div>
  </template>
}
