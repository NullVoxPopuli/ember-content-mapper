import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn, hash } from '@ember/helper';
import { service } from '@ember/service';
import type { TOC } from '@ember/component/template-only';
import type RouterService from '@ember/routing/router-service';

// ---------------------------------------------------------------------------
// Type utilities
// ---------------------------------------------------------------------------

type Nullable<T> = T | null;
type Optional<T> = T | undefined;
type ReadonlyRecord<K extends string, V> = Readonly<Record<K, V>>;

type SortDirection = 'asc' | 'desc';
type FilterOperator = 'eq' | 'neq' | 'contains';
type BadgeVariant = 'info' | 'success' | 'warning' | 'danger' | 'neutral';
type TabId = 'overview' | 'details' | 'activity' | 'settings';
type StatusType = 'active' | 'inactive' | 'pending' | 'archived';

// ---------------------------------------------------------------------------
// Data interfaces
// ---------------------------------------------------------------------------

interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
}

interface ContactInfo {
  email: string;
  phone: Nullable<string>;
  address: Address;
}

interface UserProfile {
  id: string;
  firstName: string;
  lastName: string;
  displayName: string;
  avatarUrl: Nullable<string>;
  role: 'admin' | 'editor' | 'viewer';
  contact: ContactInfo;
  createdAt: Date;
}

interface ProjectMember {
  user: UserProfile;
  joinedAt: Date;
  permissions: string[];
}

interface Tag {
  id: string;
  label: string;
  color: string;
}

interface Comment {
  id: string;
  author: UserProfile;
  body: string;
  createdAt: Date;
}

interface ActivityEntry {
  id: string;
  type: 'create' | 'update' | 'delete' | 'comment' | 'assign';
  actor: UserProfile;
  description: string;
  timestamp: Date;
  metadata: ReadonlyRecord<string, string>;
}

interface TaskItem {
  id: string;
  title: string;
  description: string;
  status: StatusType;
  priority: 'low' | 'medium' | 'high' | 'critical';
  assignee: Nullable<UserProfile>;
  tags: Tag[];
  dueDate: Nullable<Date>;
  comments: Comment[];
  subtasks: TaskItem[];
}

interface ProjectStats {
  totalTasks: number;
  completedTasks: number;
  openTasks: number;
  overdueTasks: number;
  memberCount: number;
}

interface ColumnDefinition<T> {
  key: keyof T & string;
  label: string;
  sortable: boolean;
  width: Optional<string>;
  align: 'left' | 'center' | 'right';
}

interface FilterConfig {
  field: string;
  operator: FilterOperator;
  value: string;
}

interface PaginationState {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

interface SortConfig {
  column: string;
  direction: SortDirection;
}

interface NotificationItem {
  id: string;
  message: string;
  variant: BadgeVariant;
  dismissible: boolean;
}

interface BreadcrumbItem {
  label: string;
  route: Optional<string>;
}

interface NavItem {
  id: string;
  label: string;
  icon: string;
  route: string;
  badge: Optional<number>;
  children: NavItem[];
}

// ---------------------------------------------------------------------------
// Component arg signatures
// ---------------------------------------------------------------------------

interface BadgeArgs {
  Args: {
    variant: BadgeVariant;
    label: string;
    removable?: boolean;
    onRemove?: () => void;
  };
}

interface StatusBadgeArgs {
  Args: {
    status: StatusType;
  };
}

interface AvatarArgs {
  Args: {
    src: Nullable<string>;
    name: string;
    size?: 'sm' | 'md' | 'lg';
  };
}

interface EmptyStateArgs {
  Args: {
    title: string;
    description: string;
    icon?: string;
  };
  Blocks: { default?: [] };
}

interface CardArgs {
  Args: {
    title: string;
    subtitle?: string;
  };
  Blocks: {
    header?: [];
    default: [];
    footer?: [];
  };
}

interface StatCardArgs {
  Args: {
    label: string;
    value: number;
    format?: 'number' | 'percent';
  };
}

interface BreadcrumbsArgs {
  Args: { items: BreadcrumbItem[] };
}

interface TabBarArgs {
  Args: {
    tabs: Array<{ id: TabId; label: string; count?: number }>;
    activeTab: TabId;
    onTabChange: (tab: TabId) => void;
  };
}

interface ProjectDashboardArgs {
  Args: {
    project: {
      id: string;
      name: string;
      description: string;
      status: StatusType;
      stats: ProjectStats;
      members: ProjectMember[];
      tasks: TaskItem[];
      activity: ActivityEntry[];
      tags: Tag[];
    };
    currentUser: UserProfile;
    notifications: NotificationItem[];
    navItems: NavItem[];
    breadcrumbs: BreadcrumbItem[];
  };
}

// ---------------------------------------------------------------------------
// Template-only components
// ---------------------------------------------------------------------------

const Badge: TOC<BadgeArgs> = <template>
  <span class="badge badge--{{@variant}}" role="status" ...attributes>
    {{@label}}
    {{#if @removable}}
      <button
        class="badge__remove"
        type="button"
        aria-label="Remove {{@label}}"
        {{on "click" @onRemove}}
      >&times;</button>
    {{/if}}
  </span>
</template>;

const StatusBadge: TOC<StatusBadgeArgs> = <template>
  <Badge
    @variant={{if
      (eq @status "active") "success"
      (if (eq @status "pending") "warning" "neutral")
    }}
    @label={{@status}}
  />
</template>;

const Avatar: TOC<AvatarArgs> = <template>
  <div class="avatar avatar--{{if @size @size "md"}}" ...attributes>
    {{#if @src}}
      <img class="avatar__image" src={{@src}} alt="{{@name}} avatar" loading="lazy" />
    {{else}}
      <span class="avatar__initials" aria-label={{@name}}>{{@name}}</span>
    {{/if}}
  </div>
</template>;

const EmptyState: TOC<EmptyStateArgs> = <template>
  <div class="empty-state" ...attributes>
    {{#if @icon}}
      <div class="empty-state__icon" aria-hidden="true">{{@icon}}</div>
    {{/if}}
    <h3 class="empty-state__title">{{@title}}</h3>
    <p class="empty-state__description">{{@description}}</p>
    {{yield}}
  </div>
</template>;

const Card: TOC<CardArgs> = <template>
  <article class="card" ...attributes>
    <header class="card__header">
      {{#if (has-block "header")}}
        {{yield to="header"}}
      {{else}}
        <h3 class="card__title">{{@title}}</h3>
        {{#if @subtitle}}
          <p class="card__subtitle">{{@subtitle}}</p>
        {{/if}}
      {{/if}}
    </header>
    <div class="card__body">
      {{yield}}
    </div>
    {{#if (has-block "footer")}}
      <footer class="card__footer">{{yield to="footer"}}</footer>
    {{/if}}
  </article>
</template>;

const StatCard: TOC<StatCardArgs> = <template>
  <div class="stat-card" ...attributes>
    <span class="stat-card__label">{{@label}}</span>
    <span class="stat-card__value">
      {{#if (eq @format "percent")}}
        {{@value}}%
      {{else}}
        {{@value}}
      {{/if}}
    </span>
  </div>
</template>;

const Breadcrumbs: TOC<BreadcrumbsArgs> = <template>
  <nav class="breadcrumbs" aria-label="Breadcrumb">
    <ol class="breadcrumbs__list">
      {{#each @items as |crumb|}}
        <li class="breadcrumbs__item">
          {{#if crumb.route}}
            <a class="breadcrumbs__link" href={{crumb.route}}>{{crumb.label}}</a>
            <span class="breadcrumbs__separator" aria-hidden="true">/</span>
          {{else}}
            <span class="breadcrumbs__current" aria-current="page">{{crumb.label}}</span>
          {{/if}}
        </li>
      {{/each}}
    </ol>
  </nav>
</template>;

const TabBar: TOC<TabBarArgs> = <template>
  <div class="tab-bar" role="tablist" ...attributes>
    {{#each @tabs as |tab|}}
      <button
        class="tab-bar__tab {{if (eq tab.id @activeTab) "tab-bar__tab--active"}}"
        type="button"
        role="tab"
        aria-selected={{if (eq tab.id @activeTab) "true" "false"}}
        {{on "click" (fn @onTabChange tab.id)}}
      >
        {{tab.label}}
        {{#if tab.count}}
          <span class="tab-bar__count">{{tab.count}}</span>
        {{/if}}
      </button>
    {{/each}}
  </div>
</template>;

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

function formatDate(date: Nullable<Date>): string {
  if (!date) return '---';
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return diffDays < 30 ? `${diffDays}d ago` : formatDate(date);
}

function groupBy<T>(items: T[], keyFn: (item: T) => string): Record<string, T[]> {
  const groups: Record<string, T[]> = {};
  for (const item of items) {
    const key = keyFn(item);
    if (!groups[key]) groups[key] = [];
    groups[key].push(item);
  }
  return groups;
}

function buildFilterPredicate(filters: FilterConfig[]): (task: TaskItem) => boolean {
  return (task: TaskItem) => {
    return filters.every((filter) => {
      const value = String((task as Record<string, unknown>)[filter.field] ?? '');
      switch (filter.operator) {
        case 'eq': return value === filter.value;
        case 'neq': return value !== filter.value;
        case 'contains': return value.toLowerCase().includes(filter.value.toLowerCase());
        default: return true;
      }
    });
  };
}

// ---------------------------------------------------------------------------
// Main dashboard component
// ---------------------------------------------------------------------------

export default class ProjectDashboard extends Component<ProjectDashboardArgs> {
  @service declare router: RouterService;

  @tracked activeTab: TabId = 'overview';
  @tracked searchQuery: string = '';
  @tracked sortConfig: SortConfig = { column: 'title', direction: 'asc' };
  @tracked filters: FilterConfig[] = [];
  @tracked pagination: PaginationState = { page: 1, pageSize: 25, total: 0, totalPages: 0 };
  @tracked selectedTaskIds: Set<string> = new Set();
  @tracked isCreateModalOpen: boolean = false;
  @tracked isDeleteModalOpen: boolean = false;
  @tracked isFilterPanelOpen: boolean = false;
  @tracked editingTask: Nullable<TaskItem> = null;
  @tracked expandedRowIds: Set<string> = new Set();
  @tracked sidebarCollapsed: boolean = false;
  @tracked notificationsDismissed: Set<string> = new Set();
  @tracked formErrors: Record<string, string> = {};
  @tracked newTaskTitle: string = '';
  @tracked newTaskDescription: string = '';
  @tracked newTaskPriority: TaskItem['priority'] = 'medium';
  @tracked newTaskDueDate: Nullable<string> = null;
  @tracked isDirty: boolean = false;

  get tabDefinitions(): Array<{ id: TabId; label: string; count?: number }> {
    return [
      { id: 'overview', label: 'Overview' },
      { id: 'details', label: 'Tasks', count: this.args.project.tasks.length },
      { id: 'activity', label: 'Activity', count: this.args.project.activity.length },
      { id: 'settings', label: 'Settings' },
    ];
  }

  get visibleNotifications(): NotificationItem[] {
    return this.args.notifications.filter((n) => !this.notificationsDismissed.has(n.id));
  }

  get filteredTasks(): TaskItem[] {
    let tasks = [...this.args.project.tasks];
    if (this.searchQuery.trim()) {
      const query = this.searchQuery.toLowerCase();
      tasks = tasks.filter(
        (t) =>
          t.title.toLowerCase().includes(query) ||
          t.description.toLowerCase().includes(query) ||
          t.tags.some((tag) => tag.label.toLowerCase().includes(query))
      );
    }
    if (this.filters.length > 0) {
      tasks = tasks.filter(buildFilterPredicate(this.filters));
    }
    return tasks;
  }

  get sortedTasks(): TaskItem[] {
    const tasks = [...this.filteredTasks];
    const { column, direction } = this.sortConfig;
    const multiplier = direction === 'asc' ? 1 : -1;
    tasks.sort((a, b) => {
      const aVal = String((a as Record<string, unknown>)[column] ?? '');
      const bVal = String((b as Record<string, unknown>)[column] ?? '');
      return aVal.localeCompare(bVal) * multiplier;
    });
    return tasks;
  }

  get paginatedTasks(): TaskItem[] {
    const start = (this.pagination.page - 1) * this.pagination.pageSize;
    return this.sortedTasks.slice(start, start + this.pagination.pageSize);
  }

  get hasSelectedTasks(): boolean {
    return this.selectedTaskIds.size > 0;
  }

  get allTasksSelected(): boolean {
    return this.paginatedTasks.length > 0 &&
      this.paginatedTasks.every((t) => this.selectedTaskIds.has(t.id));
  }

  get selectedCount(): number {
    return this.selectedTaskIds.size;
  }

  get completionRate(): number {
    const { stats } = this.args.project;
    if (stats.totalTasks === 0) return 0;
    return Math.round((stats.completedTasks / stats.totalTasks) * 100);
  }

  get isFormValid(): boolean {
    return this.newTaskTitle.trim().length > 0 && Object.keys(this.formErrors).length === 0;
  }

  get tableColumns(): ColumnDefinition<TaskItem>[] {
    return [
      { key: 'title', label: 'Title', sortable: true, width: undefined, align: 'left' },
      { key: 'status', label: 'Status', sortable: true, width: '120px', align: 'center' },
      { key: 'priority', label: 'Priority', sortable: true, width: '100px', align: 'center' },
      { key: 'assignee', label: 'Assignee', sortable: false, width: '160px', align: 'left' },
      { key: 'dueDate', label: 'Due Date', sortable: true, width: '140px', align: 'right' },
    ];
  }

  get recentActivity(): ActivityEntry[] {
    return this.args.project.activity.slice(0, 20);
  }

  @action handleTabChange(tabId: TabId): void {
    this.activeTab = tabId;
    this.selectedTaskIds = new Set();
  }

  @action handleSearch(event: Event): void {
    this.searchQuery = (event.target as HTMLInputElement).value;
    this.pagination = { ...this.pagination, page: 1 };
  }

  @action handleSort(column: string): void {
    if (this.sortConfig.column === column) {
      this.sortConfig = {
        column,
        direction: this.sortConfig.direction === 'asc' ? 'desc' : 'asc',
      };
    } else {
      this.sortConfig = { column, direction: 'asc' };
    }
  }

  @action handlePageChange(page: number): void {
    this.pagination = { ...this.pagination, page };
  }

  @action toggleTaskSelection(taskId: string): void {
    const next = new Set(this.selectedTaskIds);
    if (next.has(taskId)) { next.delete(taskId); } else { next.add(taskId); }
    this.selectedTaskIds = next;
  }

  @action toggleSelectAll(): void {
    if (this.allTasksSelected) {
      this.selectedTaskIds = new Set();
    } else {
      this.selectedTaskIds = new Set(this.paginatedTasks.map((t) => t.id));
    }
  }

  @action toggleRowExpansion(taskId: string): void {
    const next = new Set(this.expandedRowIds);
    if (next.has(taskId)) { next.delete(taskId); } else { next.add(taskId); }
    this.expandedRowIds = next;
  }

  @action openCreateModal(): void {
    this.isCreateModalOpen = true;
    this.resetForm();
  }

  @action closeCreateModal(): void {
    this.isCreateModalOpen = false;
    this.resetForm();
  }

  @action openDeleteModal(): void { this.isDeleteModalOpen = true; }
  @action closeDeleteModal(): void { this.isDeleteModalOpen = false; }
  @action toggleFilterPanel(): void { this.isFilterPanelOpen = !this.isFilterPanelOpen; }
  @action toggleSidebar(): void { this.sidebarCollapsed = !this.sidebarCollapsed; }

  @action dismissNotification(id: string): void {
    const next = new Set(this.notificationsDismissed);
    next.add(id);
    this.notificationsDismissed = next;
  }

  @action handleTitleInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.newTaskTitle = value;
    this.isDirty = true;
    this.validateField('title', value);
  }

  @action handleDescriptionInput(event: Event): void {
    this.newTaskDescription = (event.target as HTMLTextAreaElement).value;
    this.isDirty = true;
  }

  @action handlePriorityChange(event: Event): void {
    this.newTaskPriority = (event.target as HTMLSelectElement).value as TaskItem['priority'];
    this.isDirty = true;
  }

  @action handleFormSubmit(event: Event): void {
    event.preventDefault();
    if (!this.isFormValid) return;
    this.closeCreateModal();
  }

  @action handleDeleteConfirm(): void {
    this.selectedTaskIds = new Set();
    this.closeDeleteModal();
  }

  @action removeFilter(index: number): void {
    this.filters = this.filters.filter((_, i) => i !== index);
    this.pagination = { ...this.pagination, page: 1 };
  }

  @action clearFilters(): void {
    this.filters = [];
    this.searchQuery = '';
    this.pagination = { ...this.pagination, page: 1 };
  }

  @action navigateToTask(taskId: string): void {
    this.router.transitionTo('projects.tasks.show', taskId);
  }

  private validateField(field: string, value: string): void {
    const errors = { ...this.formErrors };
    if (field === 'title' && value.trim().length === 0) {
      errors['title'] = 'Title is required';
    } else {
      delete errors[field];
    }
    this.formErrors = errors;
  }

  private resetForm(): void {
    this.newTaskTitle = '';
    this.newTaskDescription = '';
    this.newTaskPriority = 'medium';
    this.newTaskDueDate = null;
    this.formErrors = {};
    this.isDirty = false;
  }

  <template>
    <div class="project-dashboard {{if this.sidebarCollapsed 'project-dashboard--collapsed'}}">
      {{! ---- Notifications ---- }}
      {{#each this.visibleNotifications as |notification|}}
        <div class="notification notification--{{notification.variant}}" role="alert">
          <span class="notification__message">{{notification.message}}</span>
          {{#if notification.dismissible}}
            <button
              class="notification__dismiss"
              type="button"
              aria-label="Dismiss notification"
              {{on "click" (fn this.dismissNotification notification.id)}}
            >&times;</button>
          {{/if}}
        </div>
      {{/each}}

      {{! ---- Sidebar ---- }}
      <aside class="sidebar" aria-label="Project navigation">
        <button
          class="sidebar__toggle"
          type="button"
          aria-label={{if this.sidebarCollapsed "Expand sidebar" "Collapse sidebar"}}
          {{on "click" this.toggleSidebar}}
        >{{if this.sidebarCollapsed ">>" "<<"}}</button>
        <nav class="sidebar__nav">
          {{#each @navItems as |item|}}
            <div class="sidebar__group">
              <a class="sidebar__link" href={{item.route}}>
                <span class="sidebar__icon">{{item.icon}}</span>
                {{#unless this.sidebarCollapsed}}
                  <span class="sidebar__label">{{item.label}}</span>
                  {{#if item.badge}}
                    <span class="sidebar__badge">{{item.badge}}</span>
                  {{/if}}
                {{/unless}}
              </a>
              {{#unless this.sidebarCollapsed}}
                {{#each item.children as |child|}}
                  <a class="sidebar__sublink" href={{child.route}}>
                    <span class="sidebar__icon">{{child.icon}}</span>
                    <span class="sidebar__label">{{child.label}}</span>
                  </a>
                {{/each}}
              {{/unless}}
            </div>
          {{/each}}
        </nav>
        {{#unless this.sidebarCollapsed}}
          <div class="sidebar__footer">
            <Avatar @src={{@currentUser.avatarUrl}} @name={{@currentUser.displayName}} @size="sm" />
            <span class="sidebar__user-name">{{@currentUser.displayName}}</span>
          </div>
        {{/unless}}
      </aside>

      {{! ---- Main content ---- }}
      <main class="dashboard-main">
        <Breadcrumbs @items={{@breadcrumbs}} />

        <header class="dashboard-header">
          <div class="dashboard-header__left">
            <h1 class="dashboard-header__title">{{@project.name}}</h1>
            <StatusBadge @status={{@project.status}} />
          </div>
          <div class="dashboard-header__right">
            <button class="btn btn--primary" type="button" {{on "click" this.openCreateModal}}>
              + New Task
            </button>
          </div>
        </header>

        <p class="dashboard-description">{{@project.description}}</p>

        <TabBar
          @tabs={{this.tabDefinitions}}
          @activeTab={{this.activeTab}}
          @onTabChange={{this.handleTabChange}}
        />

        {{! ---- Overview tab ---- }}
        {{#if (eq this.activeTab "overview")}}
          <section class="dashboard-section" aria-label="Project overview">
            <div class="stats-grid">
              <StatCard @label="Total Tasks" @value={{@project.stats.totalTasks}} />
              <StatCard @label="Completed" @value={{@project.stats.completedTasks}} />
              <StatCard @label="Open" @value={{@project.stats.openTasks}} />
              <StatCard @label="Overdue" @value={{@project.stats.overdueTasks}} />
              <StatCard @label="Completion" @value={{this.completionRate}} @format="percent" />
              <StatCard @label="Members" @value={{@project.stats.memberCount}} />
            </div>

            <Card @title="Team Members" @subtitle="Project contributors">
              <div class="members-grid">
                {{#each @project.members as |member|}}
                  <div class="member-card">
                    <Avatar @src={{member.user.avatarUrl}} @name={{member.user.displayName}} @size="md" />
                    <div class="member-card__info">
                      <span class="member-card__name">{{member.user.displayName}}</span>
                      <Badge @variant="info" @label={{member.user.role}} />
                    </div>
                    <span class="member-card__joined">Joined {{formatDate member.joinedAt}}</span>
                  </div>
                {{/each}}
              </div>
            </Card>

            <Card @title="Project Tags">
              <div class="tag-list">
                {{#each @project.tags as |tag|}}
                  <Badge @variant="neutral" @label={{tag.label}} />
                {{else}}
                  <EmptyState @title="No tags" @description="Add tags to organize tasks." />
                {{/each}}
              </div>
            </Card>

            <Card @title="Recent Activity">
              <ul class="activity-feed">
                {{#each this.recentActivity as |entry|}}
                  <li class="activity-feed__item">
                    <Avatar @src={{entry.actor.avatarUrl}} @name={{entry.actor.displayName}} @size="sm" />
                    <div class="activity-feed__content">
                      <span class="activity-feed__actor">{{entry.actor.displayName}}</span>
                      <span class="activity-feed__description">{{entry.description}}</span>
                      <time class="activity-feed__time">{{formatRelativeTime entry.timestamp}}</time>
                    </div>
                  </li>
                {{else}}
                  <li>
                    <EmptyState @title="No activity yet" @description="Activity will appear here." />
                  </li>
                {{/each}}
              </ul>
            </Card>
          </section>
        {{/if}}

        {{! ---- Tasks tab ---- }}
        {{#if (eq this.activeTab "details")}}
          <section class="dashboard-section" aria-label="Task management">
            <div class="toolbar">
              <div class="toolbar__left">
                <input
                  class="search-input__field"
                  type="search"
                  placeholder="Search tasks..."
                  value={{this.searchQuery}}
                  aria-label="Search tasks"
                  {{on "input" this.handleSearch}}
                />
                <button
                  class="btn btn--secondary"
                  type="button"
                  aria-expanded={{if this.isFilterPanelOpen "true" "false"}}
                  {{on "click" this.toggleFilterPanel}}
                >
                  Filters
                  {{#if this.filters.length}}
                    <span class="btn__badge">{{this.filters.length}}</span>
                  {{/if}}
                </button>
                {{#if this.hasSelectedTasks}}
                  <span class="toolbar__selection-count">{{this.selectedCount}} selected</span>
                  <button class="btn btn--danger" type="button" {{on "click" this.openDeleteModal}}>
                    Delete Selected
                  </button>
                {{/if}}
              </div>
              <div class="toolbar__right">
                {{#if this.filters.length}}
                  <button class="btn btn--ghost" type="button" {{on "click" this.clearFilters}}>
                    Clear All Filters
                  </button>
                {{/if}}
              </div>
            </div>

            {{#if this.isFilterPanelOpen}}
              <div class="filter-panel">
                {{#each this.filters as |filter index|}}
                  <div class="filter-chip">
                    <span>{{filter.field}} {{filter.operator}} "{{filter.value}}"</span>
                    <button
                      class="filter-chip__remove"
                      type="button"
                      aria-label="Remove filter"
                      {{on "click" (fn this.removeFilter index)}}
                    >&times;</button>
                  </div>
                {{/each}}
              </div>
            {{/if}}

            {{#if this.paginatedTasks.length}}
              <div class="table-wrapper" role="region" aria-label="Tasks table">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th class="data-table__th data-table__th--checkbox">
                        <input
                          type="checkbox"
                          checked={{this.allTasksSelected}}
                          aria-label="Select all tasks"
                          {{on "change" this.toggleSelectAll}}
                        />
                      </th>
                      {{#each this.tableColumns as |col|}}
                        <th class="data-table__th data-table__th--{{col.align}}">
                          {{#if col.sortable}}
                            <button
                              class="data-table__sort-btn"
                              type="button"
                              {{on "click" (fn this.handleSort col.key)}}
                            >
                              {{col.label}}
                              {{#if (eq this.sortConfig.column col.key)}}
                                <span>{{if (eq this.sortConfig.direction "asc") "^" "v"}}</span>
                              {{/if}}
                            </button>
                          {{else}}
                            {{col.label}}
                          {{/if}}
                        </th>
                      {{/each}}
                      <th class="data-table__th">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {{#each this.paginatedTasks as |task|}}
                      <tr class="data-table__row">
                        <td class="data-table__td">
                          <input
                            type="checkbox"
                            aria-label="Select {{task.title}}"
                            {{on "change" (fn this.toggleTaskSelection task.id)}}
                          />
                        </td>
                        <td class="data-table__td">
                          <div class="task-cell">
                            <button
                              class="task-cell__expand"
                              type="button"
                              {{on "click" (fn this.toggleRowExpansion task.id)}}
                            >{{if (includes this.expandedRowIds task.id) "-" "+"}}</button>
                            <span class="task-cell__title">{{task.title}}</span>
                            {{#each task.tags as |tag|}}
                              <Badge @variant="neutral" @label={{tag.label}} />
                            {{/each}}
                          </div>
                        </td>
                        <td class="data-table__td data-table__td--center">
                          <StatusBadge @status={{task.status}} />
                        </td>
                        <td class="data-table__td data-table__td--center">
                          <Badge
                            @variant={{if (eq task.priority "critical") "danger" (if (eq task.priority "high") "warning" "neutral")}}
                            @label={{task.priority}}
                          />
                        </td>
                        <td class="data-table__td">
                          {{#if task.assignee}}
                            <div class="assignee-cell">
                              <Avatar @src={{task.assignee.avatarUrl}} @name={{task.assignee.displayName}} @size="sm" />
                              <span>{{task.assignee.displayName}}</span>
                            </div>
                          {{else}}
                            <span class="text-muted">Unassigned</span>
                          {{/if}}
                        </td>
                        <td class="data-table__td data-table__td--right">
                          {{formatDate task.dueDate}}
                        </td>
                        <td class="data-table__td">
                          <button
                            class="btn btn--ghost btn--sm"
                            type="button"
                            {{on "click" (fn this.navigateToTask task.id)}}
                          >View</button>
                        </td>
                      </tr>
                      {{#if (includes this.expandedRowIds task.id)}}
                        <tr class="data-table__expanded-row">
                          <td colspan="7">
                            <div class="expanded-content">
                              <p>{{task.description}}</p>
                              {{#if task.subtasks.length}}
                                <h4>Subtasks</h4>
                                <ul class="subtask-list">
                                  {{#each task.subtasks as |subtask|}}
                                    <li class="subtask-list__item">
                                      <StatusBadge @status={{subtask.status}} />
                                      <span>{{subtask.title}}</span>
                                    </li>
                                  {{/each}}
                                </ul>
                              {{/if}}
                              {{#if task.comments.length}}
                                <h4>Comments ({{task.comments.length}})</h4>
                                <ul class="comment-list">
                                  {{#each task.comments as |comment|}}
                                    <li class="comment-list__item">
                                      <Avatar @src={{comment.author.avatarUrl}} @name={{comment.author.displayName}} @size="sm" />
                                      <div class="comment-list__body">
                                        <span>{{comment.author.displayName}}</span>
                                        <time>{{formatRelativeTime comment.createdAt}}</time>
                                        <p>{{comment.body}}</p>
                                      </div>
                                    </li>
                                  {{/each}}
                                </ul>
                              {{/if}}
                            </div>
                          </td>
                        </tr>
                      {{/if}}
                    {{/each}}
                  </tbody>
                </table>
              </div>

              <nav class="pagination" aria-label="Task pagination">
                <span class="pagination__info">
                  Page {{this.pagination.page}} of {{this.pagination.totalPages}}
                </span>
                <div class="pagination__controls">
                  <button
                    class="btn btn--secondary btn--sm"
                    type="button"
                    disabled={{eq this.pagination.page 1}}
                    {{on "click" (fn this.handlePageChange (sub this.pagination.page 1))}}
                  >Previous</button>
                  <button
                    class="btn btn--secondary btn--sm"
                    type="button"
                    disabled={{eq this.pagination.page this.pagination.totalPages}}
                    {{on "click" (fn this.handlePageChange (add this.pagination.page 1))}}
                  >Next</button>
                </div>
              </nav>
            {{else}}
              <EmptyState
                @title="No tasks found"
                @description={{if this.searchQuery "Try adjusting your search." "Create a task to get started."}}
                @icon="clipboard"
              >
                <button class="btn btn--primary" type="button" {{on "click" this.openCreateModal}}>
                  Create First Task
                </button>
              </EmptyState>
            {{/if}}
          </section>
        {{/if}}

        {{! ---- Activity tab ---- }}
        {{#if (eq this.activeTab "activity")}}
          <section class="dashboard-section" aria-label="Activity feed">
            <Card @title="All Activity">
              <ul class="activity-timeline">
                {{#each this.recentActivity as |entry|}}
                  <li class="activity-timeline__item activity-timeline__item--{{entry.type}}">
                    <div class="activity-timeline__marker"></div>
                    <div class="activity-timeline__content">
                      <Avatar @src={{entry.actor.avatarUrl}} @name={{entry.actor.displayName}} @size="sm" />
                      <div class="activity-timeline__details">
                        <span>{{entry.actor.displayName}}</span>
                        <span>{{entry.description}}</span>
                        <time>{{formatRelativeTime entry.timestamp}}</time>
                      </div>
                    </div>
                  </li>
                {{else}}
                  <li>
                    <EmptyState @title="No activity" @description="Activity entries will appear here." />
                  </li>
                {{/each}}
              </ul>
            </Card>
          </section>
        {{/if}}

        {{! ---- Settings tab ---- }}
        {{#if (eq this.activeTab "settings")}}
          <section class="dashboard-section" aria-label="Project settings">
            <Card @title="Project Information">
              <form class="form" {{on "submit" this.handleFormSubmit}}>
                <div class="form__field">
                  <label class="form__label" for="project-name">Project Name</label>
                  <input class="form__input" id="project-name" type="text" value={{@project.name}} readonly />
                </div>
                <div class="form__field">
                  <label class="form__label" for="project-desc">Description</label>
                  <textarea class="form__textarea" id="project-desc" rows="4" readonly>{{@project.description}}</textarea>
                </div>
                <div class="form__field">
                  <label class="form__label">Status</label>
                  <StatusBadge @status={{@project.status}} />
                </div>
              </form>
            </Card>

            <Card @title="Members" @subtitle="Manage team access">
              <table class="data-table data-table--compact">
                <thead>
                  <tr>
                    <th>Member</th>
                    <th>Role</th>
                    <th>Joined</th>
                    <th>Permissions</th>
                  </tr>
                </thead>
                <tbody>
                  {{#each @project.members as |member|}}
                    <tr>
                      <td>
                        <div class="assignee-cell">
                          <Avatar @src={{member.user.avatarUrl}} @name={{member.user.displayName}} @size="sm" />
                          <div>
                            <span class="text-bold">{{member.user.displayName}}</span>
                            <span class="text-muted">{{member.user.contact.email}}</span>
                          </div>
                        </div>
                      </td>
                      <td><Badge @variant="info" @label={{member.user.role}} /></td>
                      <td>{{formatDate member.joinedAt}}</td>
                      <td>
                        {{#each member.permissions as |perm|}}
                          <Badge @variant="neutral" @label={{perm}} />
                        {{/each}}
                      </td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
            </Card>

            <Card @title="Danger Zone">
              <div class="danger-zone">
                <div class="danger-zone__item">
                  <div>
                    <h4>Delete Project</h4>
                    <p class="text-muted">Permanently delete this project and all data.</p>
                  </div>
                  <button class="btn btn--danger" type="button">Delete</button>
                </div>
              </div>
            </Card>
          </section>
        {{/if}}
      </main>

      {{! ---- Create task modal ---- }}
      {{#if this.isCreateModalOpen}}
        <div class="modal-overlay" role="dialog" aria-modal="true" aria-label="Create new task">
          <div class="modal modal--lg">
            <header class="modal__header">
              <h2 class="modal__title">Create New Task</h2>
              <button class="modal__close" type="button" aria-label="Close" {{on "click" this.closeCreateModal}}>&times;</button>
            </header>
            <form class="modal__body" {{on "submit" this.handleFormSubmit}}>
              <div class="form__field">
                <label class="form__label" for="task-title">Title <span class="form__required">*</span></label>
                <input
                  class="form__input {{if (get this.formErrors 'title') 'form__input--error'}}"
                  id="task-title"
                  type="text"
                  value={{this.newTaskTitle}}
                  placeholder="Enter task title"
                  required
                  {{on "input" this.handleTitleInput}}
                />
                {{#if (get this.formErrors "title")}}
                  <span class="form__error" role="alert">{{get this.formErrors "title"}}</span>
                {{/if}}
              </div>
              <div class="form__field">
                <label class="form__label" for="task-desc">Description</label>
                <textarea
                  class="form__textarea"
                  id="task-desc"
                  rows="4"
                  value={{this.newTaskDescription}}
                  placeholder="Describe the task..."
                  {{on "input" this.handleDescriptionInput}}
                ></textarea>
              </div>
              <div class="form__row">
                <div class="form__field form__field--half">
                  <label class="form__label" for="task-priority">Priority</label>
                  <select class="form__select" id="task-priority" {{on "change" this.handlePriorityChange}}>
                    <option value="low" selected={{eq this.newTaskPriority "low"}}>Low</option>
                    <option value="medium" selected={{eq this.newTaskPriority "medium"}}>Medium</option>
                    <option value="high" selected={{eq this.newTaskPriority "high"}}>High</option>
                    <option value="critical" selected={{eq this.newTaskPriority "critical"}}>Critical</option>
                  </select>
                </div>
                <div class="form__field form__field--half">
                  <label class="form__label" for="task-assignee">Assignee</label>
                  <select class="form__select" id="task-assignee">
                    <option value="">Unassigned</option>
                    {{#each @project.members as |member|}}
                      <option value={{member.user.id}}>{{member.user.displayName}}</option>
                    {{/each}}
                  </select>
                </div>
              </div>
              <div class="form__field">
                <label class="form__label">Tags</label>
                <div class="tag-picker">
                  {{#each @project.tags as |tag|}}
                    <label class="tag-picker__option">
                      <input type="checkbox" value={{tag.id}} class="tag-picker__checkbox" />
                      <Badge @variant="neutral" @label={{tag.label}} />
                    </label>
                  {{/each}}
                </div>
              </div>
            </form>
            <footer class="modal__footer">
              <button class="btn btn--secondary" type="button" {{on "click" this.closeCreateModal}}>Cancel</button>
              <button
                class="btn btn--primary"
                type="submit"
                disabled={{not this.isFormValid}}
                {{on "click" this.handleFormSubmit}}
              >Create Task</button>
            </footer>
          </div>
        </div>
      {{/if}}

      {{! ---- Delete confirmation modal ---- }}
      {{#if this.isDeleteModalOpen}}
        <div class="modal-overlay" role="dialog" aria-modal="true" aria-label="Confirm deletion">
          <div class="modal modal--sm">
            <header class="modal__header">
              <h2 class="modal__title">Confirm Deletion</h2>
              <button class="modal__close" type="button" aria-label="Close" {{on "click" this.closeDeleteModal}}>&times;</button>
            </header>
            <div class="modal__body">
              <p>
                Are you sure you want to delete <strong>{{this.selectedCount}}</strong>
                selected task(s)? This action cannot be undone.
              </p>
            </div>
            <footer class="modal__footer">
              <button class="btn btn--secondary" type="button" {{on "click" this.closeDeleteModal}}>Cancel</button>
              <button class="btn btn--danger" type="button" {{on "click" this.handleDeleteConfirm}}>Delete Tasks</button>
            </footer>
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}
