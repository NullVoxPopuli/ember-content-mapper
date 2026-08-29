import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn, hash, array } from '@ember/helper';
import { eq, not, and, or } from 'ember-truth-helpers';
import type { TOC } from '@ember/component/template-only';

// ─── Enums ──────────────────────────────────────────────────────────────────

enum UserRole {
  Admin = 'admin',
  Editor = 'editor',
  Viewer = 'viewer',
  Moderator = 'moderator',
  SuperAdmin = 'super_admin',
}

enum NotificationType {
  Info = 'info',
  Warning = 'warning',
  Error = 'error',
  Success = 'success',
}

enum SortDirection {
  Ascending = 'asc',
  Descending = 'desc',
  None = 'none',
}

enum TabId {
  Overview = 'overview',
  Analytics = 'analytics',
  Settings = 'settings',
  Users = 'users',
  Notifications = 'notifications',
  Billing = 'billing',
}

enum ModalSize {
  Small = 'sm',
  Medium = 'md',
  Large = 'lg',
  FullScreen = 'fullscreen',
}

enum ChartType {
  Bar = 'bar',
  Line = 'line',
  Pie = 'pie',
  Area = 'area',
  Scatter = 'scatter',
}

enum ThemeMode {
  Light = 'light',
  Dark = 'dark',
  System = 'system',
}

// ─── Utility Types ──────────────────────────────────────────────────────────

type Nullable<T> = T | null;

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

type ReadonlyDeep<T> = {
  readonly [P in keyof T]: T[P] extends object ? ReadonlyDeep<T[P]> : T[P];
};

type PickByType<T, Value> = {
  [P in keyof T as T[P] extends Value ? P : never]: T[P];
};

type OmitByType<T, Value> = {
  [P in keyof T as T[P] extends Value ? never : P]: T[P];
};

type Awaited<T> = T extends Promise<infer U> ? U : T;

type ExtractArrayItem<T> = T extends Array<infer U> ? U : never;

type RequireAtLeastOne<T, Keys extends keyof T = keyof T> = Pick<
  T,
  Exclude<keyof T, Keys>
> &
  {
    [K in Keys]-?: Required<Pick<T, K>> & Partial<Pick<T, Exclude<Keys, K>>>;
  }[Keys];

type MakeOptional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

type Branded<T, Brand extends string> = T & { __brand: Brand };

// ─── Core Interfaces ────────────────────────────────────────────────────────

interface Timestamps {
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Nullable<Date>;
}

interface PaginationMeta {
  currentPage: number;
  totalPages: number;
  perPage: number;
  totalCount: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

interface ApiResponse<T> {
  data: T;
  meta: PaginationMeta;
  errors: ApiError[];
  status: number;
}

interface ApiError {
  code: string;
  message: string;
  field: Nullable<string>;
  details: Record<string, unknown>;
}

interface SortConfig<T> {
  field: keyof T;
  direction: SortDirection;
  comparator?: (a: T, b: T) => number;
}

interface FilterConfig<T> {
  field: keyof T;
  operator: 'eq' | 'neq' | 'gt' | 'lt' | 'gte' | 'lte' | 'contains' | 'in';
  value: T[keyof T] | Array<T[keyof T]>;
}

interface TableColumn<T> {
  key: keyof T & string;
  label: string;
  sortable: boolean;
  filterable: boolean;
  width: Nullable<string>;
  align: 'left' | 'center' | 'right';
  formatter?: (value: T[keyof T], row: T) => string;
  visible: boolean;
}

// ─── User Interfaces ────────────────────────────────────────────────────────

interface UserAddress {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
}

interface UserPreferences {
  theme: ThemeMode;
  language: string;
  timezone: string;
  emailNotifications: boolean;
  pushNotifications: boolean;
  weeklyDigest: boolean;
  compactView: boolean;
  defaultTab: TabId;
  itemsPerPage: number;
  dateFormat: string;
}

interface UserProfile extends Timestamps {
  id: Branded<string, 'UserId'>;
  email: string;
  firstName: string;
  lastName: string;
  displayName: string;
  avatarUrl: Nullable<string>;
  role: UserRole;
  department: string;
  title: string;
  phone: Nullable<string>;
  address: UserAddress;
  preferences: UserPreferences;
  isActive: boolean;
  lastLoginAt: Nullable<Date>;
  loginCount: number;
  tags: string[];
  metadata: Record<string, unknown>;
}

interface UserStats {
  totalUsers: number;
  activeUsers: number;
  newUsersThisWeek: number;
  newUsersThisMonth: number;
  averageSessionDuration: number;
  topDepartments: Array<{ name: string; count: number }>;
  roleDistribution: Record<UserRole, number>;
}

// ─── Notification Interfaces ────────────────────────────────────────────────

interface NotificationAction {
  label: string;
  url: Nullable<string>;
  handler: Nullable<string>;
  variant: 'primary' | 'secondary' | 'danger';
}

interface NotificationItem extends Timestamps {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  isRead: boolean;
  isDismissed: boolean;
  sender: Nullable<Pick<UserProfile, 'id' | 'displayName' | 'avatarUrl'>>;
  actions: NotificationAction[];
  expiresAt: Nullable<Date>;
  category: string;
  priority: number;
}

// ─── Chart & Analytics Interfaces ───────────────────────────────────────────

interface ChartDataPoint {
  label: string;
  value: number;
  color: Nullable<string>;
  metadata: Record<string, unknown>;
}

interface ChartSeries {
  name: string;
  data: ChartDataPoint[];
  type: ChartType;
  color: string;
  visible: boolean;
}

interface ChartConfig {
  title: string;
  subtitle: Nullable<string>;
  series: ChartSeries[];
  xAxisLabel: string;
  yAxisLabel: string;
  showLegend: boolean;
  showGrid: boolean;
  animated: boolean;
  responsive: boolean;
  height: number;
  stacked: boolean;
}

interface AnalyticsMetric {
  name: string;
  value: number;
  previousValue: number;
  changePercent: number;
  trend: 'up' | 'down' | 'stable';
  unit: string;
  description: string;
}

interface AnalyticsDashboard {
  metrics: AnalyticsMetric[];
  charts: ChartConfig[];
  dateRange: { start: Date; end: Date };
  generatedAt: Date;
  filters: Record<string, string>;
}

// ─── Form & Settings Interfaces ─────────────────────────────────────────────

interface FormField<T = string> {
  name: string;
  label: string;
  type: 'text' | 'email' | 'password' | 'number' | 'select' | 'textarea' | 'checkbox' | 'radio' | 'date';
  value: T;
  placeholder: Nullable<string>;
  required: boolean;
  disabled: boolean;
  errors: string[];
  touched: boolean;
  validators: Array<(value: T) => Nullable<string>>;
  options?: Array<{ label: string; value: string }>;
}

interface FormSection {
  title: string;
  description: Nullable<string>;
  fields: FormField[];
  collapsible: boolean;
  collapsed: boolean;
}

interface SettingsCategory {
  id: string;
  label: string;
  icon: string;
  sections: FormSection[];
  requiresAdmin: boolean;
}

// ─── Billing Interfaces ─────────────────────────────────────────────────────

interface BillingPlan {
  id: string;
  name: string;
  price: number;
  currency: string;
  interval: 'monthly' | 'yearly';
  features: string[];
  maxUsers: number;
  maxStorage: number;
  isPopular: boolean;
  isEnterprise: boolean;
}

interface Invoice extends Timestamps {
  id: string;
  number: string;
  amount: number;
  currency: string;
  status: 'paid' | 'pending' | 'overdue' | 'cancelled';
  dueDate: Date;
  paidAt: Nullable<Date>;
  items: Array<{
    description: string;
    quantity: number;
    unitPrice: number;
    total: number;
  }>;
}

// ─── Navigation Interfaces ──────────────────────────────────────────────────

interface NavItem {
  id: string;
  label: string;
  icon: Nullable<string>;
  route: Nullable<string>;
  href: Nullable<string>;
  badge: Nullable<string | number>;
  children: NavItem[];
  isActive: boolean;
  isExpanded: boolean;
  requiredRole: Nullable<UserRole>;
  dividerAfter: boolean;
}

interface BreadcrumbItem {
  label: string;
  route: Nullable<string>;
  icon: Nullable<string>;
  isCurrentPage: boolean;
}

// ─── Modal & Dialog Interfaces ──────────────────────────────────────────────

interface ModalConfig {
  title: string;
  size: ModalSize;
  closable: boolean;
  backdrop: boolean;
  animated: boolean;
  onClose: Nullable<() => void>;
  onConfirm: Nullable<() => void>;
  confirmLabel: string;
  cancelLabel: string;
  isDangerous: boolean;
}

// ─── Type Aliases ───────────────────────────────────────────────────────────

type UserId = Branded<string, 'UserId'>;
type EmailAddress = Branded<string, 'Email'>;
type UserSummary = Pick<UserProfile, 'id' | 'displayName' | 'avatarUrl' | 'role' | 'email'>;
type UserFormData = MakeOptional<Omit<UserProfile, keyof Timestamps | 'id' | 'loginCount' | 'lastLoginAt'>, 'metadata' | 'tags'>;
type SettingsFormData = DeepPartial<UserPreferences>;
type ReadonlyUser = ReadonlyDeep<UserProfile>;
type UserStringFields = PickByType<UserProfile, string>;
type UserNonStringFields = OmitByType<UserProfile, string>;
type SortableUserFields = keyof Pick<UserProfile, 'displayName' | 'email' | 'role' | 'department' | 'createdAt' | 'lastLoginAt'>;

// ─── Conditional Types ──────────────────────────────────────────────────────

type IsAdmin<T extends UserProfile> = T['role'] extends UserRole.Admin | UserRole.SuperAdmin ? true : false;

type PermissionLevel<R extends UserRole> =
  R extends UserRole.SuperAdmin ? 'full'
  : R extends UserRole.Admin ? 'elevated'
  : R extends UserRole.Moderator ? 'moderate'
  : R extends UserRole.Editor ? 'standard'
  : 'readonly';

type ResponseData<T> = T extends ApiResponse<infer D> ? D : never;

// ─── Template-Only Components ───────────────────────────────────────────────

const LoadingSpinner: TOC<{
  Args: {
    size?: 'sm' | 'md' | 'lg';
    label?: string;
    overlay?: boolean;
  };
}> = <template>
  <div class="loading-spinner loading-spinner--{{if @size @size "md"}}" role="status" aria-live="polite">
    {{#if @overlay}}
      <div class="loading-spinner__overlay">
        <div class="loading-spinner__container">
          <svg class="loading-spinner__icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <circle class="loading-spinner__track" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
            <circle class="loading-spinner__fill" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
          </svg>
          {{#if @label}}
            <span class="loading-spinner__label">{{@label}}</span>
          {{/if}}
        </div>
      </div>
    {{else}}
      <svg class="loading-spinner__icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <circle class="loading-spinner__track" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
        <circle class="loading-spinner__fill" cx="12" cy="12" r="10" fill="none" stroke-width="3" />
      </svg>
      {{#if @label}}
        <span class="loading-spinner__label">{{@label}}</span>
      {{/if}}
    {{/if}}
  </div>
</template>;

const EmptyState: TOC<{
  Args: {
    icon?: string;
    title: string;
    description?: string;
    actionLabel?: string;
    onAction?: () => void;
  };
  Blocks: {
    default?: [];
    actions?: [];
  };
}> = <template>
  <div class="empty-state" role="region" aria-label="{{@title}}">
    <div class="empty-state__content">
      {{#if @icon}}
        <div class="empty-state__icon">
          <span class="icon icon--{{@icon}}" aria-hidden="true"></span>
        </div>
      {{/if}}
      <h3 class="empty-state__title">{{@title}}</h3>
      {{#if @description}}
        <p class="empty-state__description">{{@description}}</p>
      {{/if}}
      {{yield}}
      {{#if (has-block "actions")}}
        <div class="empty-state__actions">
          {{yield to="actions"}}
        </div>
      {{else if @actionLabel}}
        <div class="empty-state__actions">
          <button type="button" class="btn btn--primary" {{on "click" @onAction}}>
            {{@actionLabel}}
          </button>
        </div>
      {{/if}}
    </div>
  </div>
</template>;

const Badge: TOC<{
  Args: {
    label: string;
    variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info';
    size?: 'sm' | 'md' | 'lg';
    removable?: boolean;
    onRemove?: () => void;
  };
}> = <template>
  <span class="badge badge--{{if @variant @variant "default"}} badge--{{if @size @size "md"}}">
    <span class="badge__text">{{@label}}</span>
    {{#if @removable}}
      <button
        type="button"
        class="badge__remove"
        aria-label="Remove {{@label}}"
        {{on "click" @onRemove}}
      >
        <span class="icon icon--close" aria-hidden="true"></span>
      </button>
    {{/if}}
  </span>
</template>;

const Avatar: TOC<{
  Args: {
    src?: Nullable<string>;
    alt: string;
    size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
    initials?: string;
    status?: 'online' | 'offline' | 'busy' | 'away';
  };
}> = <template>
  <div class="avatar avatar--{{if @size @size "md"}}" role="img" aria-label="{{@alt}}">
    {{#if @src}}
      <img class="avatar__image" src={{@src}} alt={{@alt}} loading="lazy" />
    {{else if @initials}}
      <span class="avatar__initials">{{@initials}}</span>
    {{else}}
      <span class="avatar__placeholder">
        <span class="icon icon--user" aria-hidden="true"></span>
      </span>
    {{/if}}
    {{#if @status}}
      <span class="avatar__status avatar__status--{{@status}}" aria-label="Status: {{@status}}"></span>
    {{/if}}
  </div>
</template>;

const MetricCard: TOC<{
  Args: {
    title: string;
    value: string | number;
    previousValue?: string | number;
    changePercent?: number;
    trend?: 'up' | 'down' | 'stable';
    unit?: string;
    icon?: string;
    loading?: boolean;
  };
}> = <template>
  <div class="metric-card" role="region" aria-label="{{@title}}">
    {{#if @loading}}
      <LoadingSpinner @size="sm" @label="Loading metric..." />
    {{else}}
      <div class="metric-card__header">
        {{#if @icon}}
          <span class="metric-card__icon icon icon--{{@icon}}" aria-hidden="true"></span>
        {{/if}}
        <h4 class="metric-card__title">{{@title}}</h4>
      </div>
      <div class="metric-card__body">
        <span class="metric-card__value">
          {{@value}}
          {{#if @unit}}
            <span class="metric-card__unit">{{@unit}}</span>
          {{/if}}
        </span>
        {{#if @changePercent}}
          <span class="metric-card__change metric-card__change--{{if @trend @trend "stable"}}">
            {{#if (eq @trend "up")}}
              <span class="icon icon--arrow-up" aria-hidden="true"></span>
            {{else if (eq @trend "down")}}
              <span class="icon icon--arrow-down" aria-hidden="true"></span>
            {{else}}
              <span class="icon icon--minus" aria-hidden="true"></span>
            {{/if}}
            {{@changePercent}}%
          </span>
        {{/if}}
      </div>
      {{#if @previousValue}}
        <div class="metric-card__footer">
          <span class="metric-card__previous">Previous: {{@previousValue}}</span>
        </div>
      {{/if}}
    {{/if}}
  </div>
</template>;

const Breadcrumbs: TOC<{
  Args: {
    items: BreadcrumbItem[];
    separator?: string;
  };
}> = <template>
  <nav class="breadcrumbs" aria-label="Breadcrumb">
    <ol class="breadcrumbs__list">
      {{#each @items as |crumb index|}}
        <li class="breadcrumbs__item {{if crumb.isCurrentPage "breadcrumbs__item--current"}}">
          {{#if crumb.icon}}
            <span class="breadcrumbs__icon icon icon--{{crumb.icon}}" aria-hidden="true"></span>
          {{/if}}
          {{#if crumb.isCurrentPage}}
            <span class="breadcrumbs__text" aria-current="page">{{crumb.label}}</span>
          {{else if crumb.route}}
            <a class="breadcrumbs__link" href={{crumb.route}}>{{crumb.label}}</a>
          {{else}}
            <span class="breadcrumbs__text">{{crumb.label}}</span>
          {{/if}}
          {{#unless crumb.isCurrentPage}}
            <span class="breadcrumbs__separator" aria-hidden="true">
              {{if @separator @separator "/"}}
            </span>
          {{/unless}}
        </li>
      {{/each}}
    </ol>
  </nav>
</template>;

const Pagination: TOC<{
  Args: {
    meta: PaginationMeta;
    onPageChange: (page: number) => void;
    onPerPageChange?: (perPage: number) => void;
    showPerPage?: boolean;
  };
}> = <template>
  <nav class="pagination" aria-label="Pagination">
    <div class="pagination__info">
      <span class="pagination__count">
        Showing page {{@meta.currentPage}} of {{@meta.totalPages}}
        ({{@meta.totalCount}} total items)
      </span>
    </div>
    <div class="pagination__controls">
      <button
        type="button"
        class="pagination__btn pagination__btn--prev"
        disabled={{not @meta.hasPreviousPage}}
        {{on "click" (fn @onPageChange (if @meta.hasPreviousPage 1 @meta.currentPage))}}
      >
        <span class="icon icon--chevron-left" aria-hidden="true"></span>
        Previous
      </button>
      <span class="pagination__current" aria-current="page">
        {{@meta.currentPage}}
      </span>
      <button
        type="button"
        class="pagination__btn pagination__btn--next"
        disabled={{not @meta.hasNextPage}}
        {{on "click" (fn @onPageChange (if @meta.hasNextPage @meta.totalPages @meta.currentPage))}}
      >
        Next
        <span class="icon icon--chevron-right" aria-hidden="true"></span>
      </button>
    </div>
    {{#if @showPerPage}}
      <div class="pagination__per-page">
        <label class="pagination__per-page-label" for="per-page-select">Items per page:</label>
        <select
          id="per-page-select"
          class="pagination__per-page-select"
          {{on "change" @onPerPageChange}}
        >
          <option value="10">10</option>
          <option value="25">25</option>
          <option value="50">50</option>
          <option value="100">100</option>
        </select>
      </div>
    {{/if}}
  </nav>
</template>;

const ModalDialog: TOC<{
  Args: {
    title: string;
    isOpen: boolean;
    size?: ModalSize;
    closable?: boolean;
    isDangerous?: boolean;
    confirmLabel?: string;
    cancelLabel?: string;
    onClose: () => void;
    onConfirm?: () => void;
  };
  Blocks: {
    default: [];
    footer?: [];
  };
}> = <template>
  {{#if @isOpen}}
    <div class="modal-overlay {{if @isDangerous "modal-overlay--dangerous"}}" role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <div class="modal modal--{{if @size @size "md"}}">
        <div class="modal__header">
          <h2 class="modal__title" id="modal-title">{{@title}}</h2>
          {{#if @closable}}
            <button
              type="button"
              class="modal__close"
              aria-label="Close dialog"
              {{on "click" @onClose}}
            >
              <span class="icon icon--close" aria-hidden="true"></span>
            </button>
          {{/if}}
        </div>
        <div class="modal__body">
          {{yield}}
        </div>
        {{#if (has-block "footer")}}
          <div class="modal__footer">
            {{yield to="footer"}}
          </div>
        {{else}}
          <div class="modal__footer">
            <button
              type="button"
              class="btn btn--secondary"
              {{on "click" @onClose}}
            >
              {{if @cancelLabel @cancelLabel "Cancel"}}
            </button>
            {{#if @onConfirm}}
              <button
                type="button"
                class="btn {{if @isDangerous "btn--danger" "btn--primary"}}"
                {{on "click" @onConfirm}}
              >
                {{if @confirmLabel @confirmLabel "Confirm"}}
              </button>
            {{/if}}
          </div>
        {{/if}}
      </div>
    </div>
  {{/if}}
</template>;

const TabBar: TOC<{
  Args: {
    tabs: Array<{ id: string; label: string; icon?: string; badge?: string | number; disabled?: boolean }>;
    activeTabId: string;
    onTabChange: (tabId: string) => void;
    variant?: 'underline' | 'pills' | 'boxed';
  };
}> = <template>
  <div class="tab-bar tab-bar--{{if @variant @variant "underline"}}" role="tablist">
    {{#each @tabs as |tab|}}
      <button
        type="button"
        class="tab-bar__tab {{if (eq tab.id @activeTabId) "tab-bar__tab--active"}} {{if tab.disabled "tab-bar__tab--disabled"}}"
        role="tab"
        aria-selected={{if (eq tab.id @activeTabId) "true" "false"}}
        aria-controls="panel-{{tab.id}}"
        id="tab-{{tab.id}}"
        disabled={{tab.disabled}}
        {{on "click" (fn @onTabChange tab.id)}}
      >
        {{#if tab.icon}}
          <span class="tab-bar__icon icon icon--{{tab.icon}}" aria-hidden="true"></span>
        {{/if}}
        <span class="tab-bar__label">{{tab.label}}</span>
        {{#if tab.badge}}
          <span class="tab-bar__badge">{{tab.badge}}</span>
        {{/if}}
      </button>
    {{/each}}
  </div>
</template>;

const NotificationToast: TOC<{
  Args: {
    notification: NotificationItem;
    onDismiss: (id: string) => void;
    onMarkRead: (id: string) => void;
    onActionClick: (notificationId: string, actionIndex: number) => void;
  };
}> = <template>
  <div
    class="notification-toast notification-toast--{{@notification.type}} {{if @notification.isRead "notification-toast--read"}}"
    role="alert"
    aria-live="polite"
  >
    <div class="notification-toast__icon">
      {{#if (eq @notification.type "info")}}
        <span class="icon icon--info-circle" aria-hidden="true"></span>
      {{else if (eq @notification.type "warning")}}
        <span class="icon icon--exclamation-triangle" aria-hidden="true"></span>
      {{else if (eq @notification.type "error")}}
        <span class="icon icon--x-circle" aria-hidden="true"></span>
      {{else if (eq @notification.type "success")}}
        <span class="icon icon--check-circle" aria-hidden="true"></span>
      {{/if}}
    </div>
    <div class="notification-toast__content">
      <h4 class="notification-toast__title">{{@notification.title}}</h4>
      <p class="notification-toast__message">{{@notification.message}}</p>
      {{#if @notification.sender}}
        <div class="notification-toast__sender">
          <Avatar
            @src={{@notification.sender.avatarUrl}}
            @alt={{@notification.sender.displayName}}
            @size="xs"
          />
          <span class="notification-toast__sender-name">{{@notification.sender.displayName}}</span>
        </div>
      {{/if}}
      {{#if @notification.actions.length}}
        <div class="notification-toast__actions">
          {{#each @notification.actions as |notifAction actionIdx|}}
            <button
              type="button"
              class="btn btn--{{notifAction.variant}} btn--sm"
              {{on "click" (fn @onActionClick @notification.id actionIdx)}}
            >
              {{notifAction.label}}
            </button>
          {{/each}}
        </div>
      {{/if}}
    </div>
    <div class="notification-toast__controls">
      {{#unless @notification.isRead}}
        <button
          type="button"
          class="notification-toast__mark-read"
          aria-label="Mark as read"
          {{on "click" (fn @onMarkRead @notification.id)}}
        >
          <span class="icon icon--check" aria-hidden="true"></span>
        </button>
      {{/unless}}
      <button
        type="button"
        class="notification-toast__dismiss"
        aria-label="Dismiss notification"
        {{on "click" (fn @onDismiss @notification.id)}}
      >
        <span class="icon icon--x" aria-hidden="true"></span>
      </button>
    </div>
  </div>
</template>;

const DataTableRow: TOC<{
  Args: {
    columns: Array<{ key: string; align: string; width: Nullable<string> }>;
    row: Record<string, unknown>;
    isSelected: boolean;
    onSelect: (row: Record<string, unknown>) => void;
    onRowClick: (row: Record<string, unknown>) => void;
  };
}> = <template>
  <tr
    class="data-table__row {{if @isSelected "data-table__row--selected"}}"
    role="row"
    {{on "click" (fn @onRowClick @row)}}
  >
    <td class="data-table__cell data-table__cell--checkbox">
      <input
        type="checkbox"
        checked={{@isSelected}}
        aria-label="Select row"
        {{on "click" (fn @onSelect @row)}}
      />
    </td>
    {{#each @columns as |col|}}
      <td
        class="data-table__cell data-table__cell--{{col.align}}"
        style={{if col.width (hash width=col.width)}}
      >
        {{get @row col.key}}
      </td>
    {{/each}}
    <td class="data-table__cell data-table__cell--actions">
      <button type="button" class="btn btn--icon btn--sm" aria-label="Row actions">
        <span class="icon icon--dots-vertical" aria-hidden="true"></span>
      </button>
    </td>
  </tr>
</template>;

const ChartPlaceholder: TOC<{
  Args: {
    config: ChartConfig;
    loading?: boolean;
  };
}> = <template>
  <div class="chart-placeholder" role="img" aria-label="{{@config.title}} chart">
    <div class="chart-placeholder__header">
      <h4 class="chart-placeholder__title">{{@config.title}}</h4>
      {{#if @config.subtitle}}
        <p class="chart-placeholder__subtitle">{{@config.subtitle}}</p>
      {{/if}}
    </div>
    {{#if @loading}}
      <div class="chart-placeholder__loading">
        <LoadingSpinner @size="md" @label="Loading chart data..." />
      </div>
    {{else}}
      <div class="chart-placeholder__body" style="height: {{@config.height}}px;">
        <div class="chart-placeholder__canvas">
          {{#each @config.series as |series|}}
            <div class="chart-placeholder__series" data-type={{series.type}} data-name={{series.name}}>
              {{#if series.visible}}
                {{#each series.data as |point|}}
                  <div
                    class="chart-placeholder__point"
                    data-value={{point.value}}
                    data-label={{point.label}}
                    title="{{point.label}}: {{point.value}}"
                  >
                    <span class="chart-placeholder__bar" style="height: {{point.value}}%; background: {{if point.color point.color series.color}};"></span>
                  </div>
                {{/each}}
              {{/if}}
            </div>
          {{/each}}
        </div>
        <div class="chart-placeholder__axes">
          <span class="chart-placeholder__x-label">{{@config.xAxisLabel}}</span>
          <span class="chart-placeholder__y-label">{{@config.yAxisLabel}}</span>
        </div>
      </div>
      {{#if @config.showLegend}}
        <div class="chart-placeholder__legend">
          {{#each @config.series as |series|}}
            <div class="chart-placeholder__legend-item">
              <span class="chart-placeholder__legend-color" style="background: {{series.color}};"></span>
              <span class="chart-placeholder__legend-label">{{series.name}}</span>
            </div>
          {{/each}}
        </div>
      {{/if}}
    {{/if}}
  </div>
</template>;

const SidebarNav: TOC<{
  Args: {
    items: NavItem[];
    collapsed: boolean;
    onToggle: () => void;
    onItemClick: (item: NavItem) => void;
  };
}> = <template>
  <aside class="sidebar-nav {{if @collapsed "sidebar-nav--collapsed"}}" role="navigation" aria-label="Main navigation">
    <div class="sidebar-nav__header">
      {{#unless @collapsed}}
        <span class="sidebar-nav__logo">Dashboard</span>
      {{/unless}}
      <button
        type="button"
        class="sidebar-nav__toggle"
        aria-label={{if @collapsed "Expand sidebar" "Collapse sidebar"}}
        {{on "click" @onToggle}}
      >
        <span class="icon icon--{{if @collapsed "chevron-right" "chevron-left"}}" aria-hidden="true"></span>
      </button>
    </div>
    <nav class="sidebar-nav__menu">
      <ul class="sidebar-nav__list">
        {{#each @items as |item|}}
          <li class="sidebar-nav__item {{if item.isActive "sidebar-nav__item--active"}}">
            <button
              type="button"
              class="sidebar-nav__link"
              aria-current={{if item.isActive "page"}}
              {{on "click" (fn @onItemClick item)}}
            >
              {{#if item.icon}}
                <span class="sidebar-nav__icon icon icon--{{item.icon}}" aria-hidden="true"></span>
              {{/if}}
              {{#unless @collapsed}}
                <span class="sidebar-nav__label">{{item.label}}</span>
                {{#if item.badge}}
                  <span class="sidebar-nav__badge">{{item.badge}}</span>
                {{/if}}
              {{/unless}}
            </button>
            {{#if (and item.children.length (not @collapsed))}}
              {{#if item.isExpanded}}
                <ul class="sidebar-nav__sublist">
                  {{#each item.children as |child|}}
                    <li class="sidebar-nav__subitem {{if child.isActive "sidebar-nav__subitem--active"}}">
                      <button
                        type="button"
                        class="sidebar-nav__sublink"
                        {{on "click" (fn @onItemClick child)}}
                      >
                        {{child.label}}
                        {{#if child.badge}}
                          <span class="sidebar-nav__badge">{{child.badge}}</span>
                        {{/if}}
                      </button>
                    </li>
                  {{/each}}
                </ul>
              {{/if}}
            {{/if}}
            {{#if item.dividerAfter}}
              <hr class="sidebar-nav__divider" />
            {{/if}}
          </li>
        {{/each}}
      </ul>
    </nav>
    {{#unless @collapsed}}
      <div class="sidebar-nav__footer">
        <span class="sidebar-nav__version">v2.14.0</span>
      </div>
    {{/unless}}
  </aside>
</template>;

const FormFieldComponent: TOC<{
  Args: {
    field: FormField;
    onInput: (name: string, value: string) => void;
    onBlur: (name: string) => void;
  };
}> = <template>
  <div class="form-field {{if @field.errors.length "form-field--error"}} {{if @field.touched "form-field--touched"}}">
    <label class="form-field__label" for="field-{{@field.name}}">
      {{@field.label}}
      {{#if @field.required}}
        <span class="form-field__required" aria-label="Required">*</span>
      {{/if}}
    </label>
    {{#if (eq @field.type "textarea")}}
      <textarea
        id="field-{{@field.name}}"
        class="form-field__input form-field__textarea"
        placeholder={{@field.placeholder}}
        disabled={{@field.disabled}}
        required={{@field.required}}
        aria-invalid={{if @field.errors.length "true" "false"}}
        aria-describedby="field-{{@field.name}}-errors"
        {{on "input" (fn @onInput @field.name)}}
        {{on "blur" (fn @onBlur @field.name)}}
      >{{@field.value}}</textarea>
    {{else if (eq @field.type "select")}}
      <select
        id="field-{{@field.name}}"
        class="form-field__input form-field__select"
        disabled={{@field.disabled}}
        required={{@field.required}}
        aria-invalid={{if @field.errors.length "true" "false"}}
        {{on "change" (fn @onInput @field.name)}}
        {{on "blur" (fn @onBlur @field.name)}}
      >
        <option value="">{{if @field.placeholder @field.placeholder "Select..."}}</option>
        {{#each @field.options as |opt|}}
          <option value={{opt.value}} selected={{eq opt.value @field.value}}>
            {{opt.label}}
          </option>
        {{/each}}
      </select>
    {{else if (eq @field.type "checkbox")}}
      <div class="form-field__checkbox-wrapper">
        <input
          type="checkbox"
          id="field-{{@field.name}}"
          class="form-field__checkbox"
          checked={{@field.value}}
          disabled={{@field.disabled}}
          {{on "change" (fn @onInput @field.name)}}
        />
        <span class="form-field__checkbox-label">{{@field.label}}</span>
      </div>
    {{else}}
      <input
        type={{@field.type}}
        id="field-{{@field.name}}"
        class="form-field__input"
        value={{@field.value}}
        placeholder={{@field.placeholder}}
        disabled={{@field.disabled}}
        required={{@field.required}}
        aria-invalid={{if @field.errors.length "true" "false"}}
        aria-describedby="field-{{@field.name}}-errors"
        {{on "input" (fn @onInput @field.name)}}
        {{on "blur" (fn @onBlur @field.name)}}
      />
    {{/if}}
    {{#if @field.errors.length}}
      <div id="field-{{@field.name}}-errors" class="form-field__errors" role="alert">
        {{#each @field.errors as |error|}}
          <span class="form-field__error-message">{{error}}</span>
        {{/each}}
      </div>
    {{/if}}
  </div>
</template>;

const BillingPlanCard: TOC<{
  Args: {
    plan: BillingPlan;
    isCurrentPlan: boolean;
    onSelect: (planId: string) => void;
  };
}> = <template>
  <div class="billing-plan-card {{if @plan.isPopular "billing-plan-card--popular"}} {{if @isCurrentPlan "billing-plan-card--current"}} {{if @plan.isEnterprise "billing-plan-card--enterprise"}}">
    {{#if @plan.isPopular}}
      <div class="billing-plan-card__badge">Most Popular</div>
    {{/if}}
    <div class="billing-plan-card__header">
      <h3 class="billing-plan-card__name">{{@plan.name}}</h3>
      <div class="billing-plan-card__pricing">
        {{#if @plan.isEnterprise}}
          <span class="billing-plan-card__price">Custom</span>
        {{else}}
          <span class="billing-plan-card__currency">{{@plan.currency}}</span>
          <span class="billing-plan-card__price">{{@plan.price}}</span>
          <span class="billing-plan-card__interval">/{{@plan.interval}}</span>
        {{/if}}
      </div>
    </div>
    <div class="billing-plan-card__body">
      <ul class="billing-plan-card__features">
        {{#each @plan.features as |feature|}}
          <li class="billing-plan-card__feature">
            <span class="icon icon--check" aria-hidden="true"></span>
            {{feature}}
          </li>
        {{/each}}
      </ul>
      <div class="billing-plan-card__limits">
        <span class="billing-plan-card__limit">
          <strong>{{@plan.maxUsers}}</strong> users
        </span>
        <span class="billing-plan-card__limit">
          <strong>{{@plan.maxStorage}}</strong> GB storage
        </span>
      </div>
    </div>
    <div class="billing-plan-card__footer">
      {{#if @isCurrentPlan}}
        <button type="button" class="btn btn--secondary btn--full" disabled>
          Current Plan
        </button>
      {{else if @plan.isEnterprise}}
        <button type="button" class="btn btn--primary btn--full" {{on "click" (fn @onSelect @plan.id)}}>
          Contact Sales
        </button>
      {{else}}
        <button type="button" class="btn btn--primary btn--full" {{on "click" (fn @onSelect @plan.id)}}>
          Select Plan
        </button>
      {{/if}}
    </div>
  </div>
</template>;

// ─── Class-Based Components ─────────────────────────────────────────────────

interface UserManagementSignature {
  Args: {
    users: UserProfile[];
    currentUser: UserProfile;
    stats: UserStats;
    onUpdateUser: (userId: UserId, data: DeepPartial<UserProfile>) => Promise<void>;
    onDeleteUser: (userId: UserId) => Promise<void>;
    onInviteUser: (email: string, role: UserRole) => Promise<void>;
  };
  Blocks: {
    default: [];
  };
}

class UserManagementPanel extends Component<UserManagementSignature> {
  @tracked declare searchQuery: string;
  @tracked declare selectedRole: Nullable<UserRole>;
  @tracked declare sortField: SortableUserFields;
  @tracked declare sortDirection: SortDirection;
  @tracked declare selectedUsers: Set<UserId>;
  @tracked declare isInviteModalOpen: boolean;
  @tracked declare inviteEmail: string;
  @tracked declare inviteRole: UserRole;
  @tracked declare isDeleteModalOpen: boolean;
  @tracked declare userToDelete: Nullable<UserProfile>;
  @tracked declare isEditModalOpen: boolean;
  @tracked declare userToEdit: Nullable<UserProfile>;
  @tracked declare currentPage: number;
  @tracked declare perPage: number;
  @tracked declare isLoading: boolean;
  @tracked declare isBulkActionOpen: boolean;

  constructor(owner: unknown, args: UserManagementSignature['Args']) {
    super(owner, args);
    this.searchQuery = '';
    this.selectedRole = null;
    this.sortField = 'displayName';
    this.sortDirection = SortDirection.Ascending;
    this.selectedUsers = new Set();
    this.isInviteModalOpen = false;
    this.inviteEmail = '';
    this.inviteRole = UserRole.Viewer;
    this.isDeleteModalOpen = false;
    this.userToDelete = null;
    this.isEditModalOpen = false;
    this.userToEdit = null;
    this.currentPage = 1;
    this.perPage = 25;
    this.isLoading = false;
    this.isBulkActionOpen = false;
  }

  get filteredUsers(): UserProfile[] {
    let users = [...this.args.users];

    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      users = users.filter(
        (u) =>
          u.displayName.toLowerCase().includes(query) ||
          u.email.toLowerCase().includes(query) ||
          u.department.toLowerCase().includes(query),
      );
    }

    if (this.selectedRole) {
      users = users.filter((u) => u.role === this.selectedRole);
    }

    return users;
  }

  get sortedUsers(): UserProfile[] {
    const users = [...this.filteredUsers];
    const dir = this.sortDirection === SortDirection.Ascending ? 1 : -1;
    const field = this.sortField;

    return users.sort((a, b) => {
      const aVal = a[field];
      const bVal = b[field];
      if (aVal === null || aVal === undefined) return 1;
      if (bVal === null || bVal === undefined) return -1;
      if (aVal < bVal) return -1 * dir;
      if (aVal > bVal) return 1 * dir;
      return 0;
    });
  }

  get paginatedUsers(): UserProfile[] {
    const start = (this.currentPage - 1) * this.perPage;
    return this.sortedUsers.slice(start, start + this.perPage);
  }

  get paginationMeta(): PaginationMeta {
    const totalCount = this.sortedUsers.length;
    const totalPages = Math.ceil(totalCount / this.perPage);
    return {
      currentPage: this.currentPage,
      totalPages,
      perPage: this.perPage,
      totalCount,
      hasNextPage: this.currentPage < totalPages,
      hasPreviousPage: this.currentPage > 1,
    };
  }

  get hasSelectedUsers(): boolean {
    return this.selectedUsers.size > 0;
  }

  get selectedCount(): number {
    return this.selectedUsers.size;
  }

  get isAllSelected(): boolean {
    return this.selectedUsers.size === this.paginatedUsers.length && this.paginatedUsers.length > 0;
  }

  get canInviteUsers(): boolean {
    return (
      this.args.currentUser.role === UserRole.Admin ||
      this.args.currentUser.role === UserRole.SuperAdmin
    );
  }

  get canDeleteUsers(): boolean {
    return this.args.currentUser.role === UserRole.SuperAdmin;
  }

  get roleOptions(): Array<{ label: string; value: UserRole }> {
    return [
      { label: 'Viewer', value: UserRole.Viewer },
      { label: 'Editor', value: UserRole.Editor },
      { label: 'Moderator', value: UserRole.Moderator },
      { label: 'Admin', value: UserRole.Admin },
    ];
  }

  get userTableColumns(): Array<TableColumn<UserProfile>> {
    return [
      { key: 'displayName', label: 'Name', sortable: true, filterable: true, width: null, align: 'left', visible: true },
      { key: 'email', label: 'Email', sortable: true, filterable: true, width: null, align: 'left', visible: true },
      { key: 'role', label: 'Role', sortable: true, filterable: true, width: '120px', align: 'center', visible: true },
      { key: 'department', label: 'Department', sortable: true, filterable: true, width: '150px', align: 'left', visible: true },
      { key: 'isActive', label: 'Status', sortable: false, filterable: true, width: '100px', align: 'center', visible: true },
    ];
  }

  @action
  handleSearch(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.searchQuery = target.value;
    this.currentPage = 1;
  }

  @action
  handleRoleFilter(role: Nullable<UserRole>): void {
    this.selectedRole = role;
    this.currentPage = 1;
  }

  @action
  handleSort(field: SortableUserFields): void {
    if (this.sortField === field) {
      this.sortDirection =
        this.sortDirection === SortDirection.Ascending
          ? SortDirection.Descending
          : SortDirection.Ascending;
    } else {
      this.sortField = field;
      this.sortDirection = SortDirection.Ascending;
    }
  }

  @action
  toggleUserSelection(userId: UserId): void {
    const newSet = new Set(this.selectedUsers);
    if (newSet.has(userId)) {
      newSet.delete(userId);
    } else {
      newSet.add(userId);
    }
    this.selectedUsers = newSet;
  }

  @action
  toggleSelectAll(): void {
    if (this.isAllSelected) {
      this.selectedUsers = new Set();
    } else {
      this.selectedUsers = new Set(this.paginatedUsers.map((u) => u.id));
    }
  }

  @action
  openInviteModal(): void {
    this.isInviteModalOpen = true;
    this.inviteEmail = '';
    this.inviteRole = UserRole.Viewer;
  }

  @action
  closeInviteModal(): void {
    this.isInviteModalOpen = false;
  }

  @action
  async handleInvite(): Promise<void> {
    this.isLoading = true;
    try {
      await this.args.onInviteUser(this.inviteEmail, this.inviteRole);
      this.isInviteModalOpen = false;
    } finally {
      this.isLoading = false;
    }
  }

  @action
  openDeleteModal(user: UserProfile): void {
    this.userToDelete = user;
    this.isDeleteModalOpen = true;
  }

  @action
  closeDeleteModal(): void {
    this.isDeleteModalOpen = false;
    this.userToDelete = null;
  }

  @action
  async handleDelete(): Promise<void> {
    if (!this.userToDelete) return;
    this.isLoading = true;
    try {
      await this.args.onDeleteUser(this.userToDelete.id);
      this.isDeleteModalOpen = false;
      this.userToDelete = null;
    } finally {
      this.isLoading = false;
    }
  }

  @action
  handlePageChange(page: number): void {
    this.currentPage = page;
  }

  @action
  handlePerPageChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.perPage = parseInt(target.value, 10);
    this.currentPage = 1;
  }

  <template>
    <section class="user-management" aria-label="User Management">
      <div class="user-management__header">
        <div class="user-management__title-row">
          <h2 class="user-management__title">User Management</h2>
          {{#if this.canInviteUsers}}
            <button
              type="button"
              class="btn btn--primary"
              {{on "click" this.openInviteModal}}
            >
              <span class="icon icon--plus" aria-hidden="true"></span>
              Invite User
            </button>
          {{/if}}
        </div>

        <div class="user-management__stats">
          <MetricCard
            @title="Total Users"
            @value={{this.args.stats.totalUsers}}
            @icon="users"
          />
          <MetricCard
            @title="Active Users"
            @value={{this.args.stats.activeUsers}}
            @icon="user-check"
            @trend="up"
            @changePercent={{12}}
          />
          <MetricCard
            @title="New This Week"
            @value={{this.args.stats.newUsersThisWeek}}
            @icon="user-plus"
            @trend="up"
            @changePercent={{8}}
          />
          <MetricCard
            @title="New This Month"
            @value={{this.args.stats.newUsersThisMonth}}
            @icon="calendar"
            @trend="stable"
            @changePercent={{0}}
          />
        </div>

        <div class="user-management__filters">
          <div class="user-management__search">
            <span class="icon icon--search" aria-hidden="true"></span>
            <input
              type="search"
              class="user-management__search-input"
              placeholder="Search users by name, email, or department..."
              value={{this.searchQuery}}
              aria-label="Search users"
              {{on "input" this.handleSearch}}
            />
          </div>

          <div class="user-management__role-filter">
            <button
              type="button"
              class="btn btn--sm {{unless this.selectedRole "btn--active"}}"
              {{on "click" (fn this.handleRoleFilter null)}}
            >
              All Roles
            </button>
            {{#each this.roleOptions as |roleOpt|}}
              <button
                type="button"
                class="btn btn--sm {{if (eq this.selectedRole roleOpt.value) "btn--active"}}"
                {{on "click" (fn this.handleRoleFilter roleOpt.value)}}
              >
                {{roleOpt.label}}
              </button>
            {{/each}}
          </div>
        </div>

        {{#if this.hasSelectedUsers}}
          <div class="user-management__bulk-actions" role="toolbar" aria-label="Bulk actions">
            <span class="user-management__selected-count">
              {{this.selectedCount}} user(s) selected
            </span>
            <button type="button" class="btn btn--sm btn--secondary">
              <span class="icon icon--mail" aria-hidden="true"></span>
              Email Selected
            </button>
            <button type="button" class="btn btn--sm btn--secondary">
              <span class="icon icon--download" aria-hidden="true"></span>
              Export Selected
            </button>
            {{#if this.canDeleteUsers}}
              <button type="button" class="btn btn--sm btn--danger">
                <span class="icon icon--trash" aria-hidden="true"></span>
                Delete Selected
              </button>
            {{/if}}
          </div>
        {{/if}}
      </div>

      <div class="user-management__table-wrapper">
        {{#if this.isLoading}}
          <LoadingSpinner @size="lg" @label="Loading users..." @overlay={{true}} />
        {{/if}}

        {{#if this.paginatedUsers.length}}
          <table class="data-table" role="grid" aria-label="Users table">
            <thead class="data-table__head">
              <tr class="data-table__header-row">
                <th class="data-table__header data-table__header--checkbox">
                  <input
                    type="checkbox"
                    checked={{this.isAllSelected}}
                    aria-label="Select all users"
                    {{on "change" this.toggleSelectAll}}
                  />
                </th>
                {{#each this.userTableColumns as |col|}}
                  {{#if col.visible}}
                    <th
                      class="data-table__header data-table__header--{{col.align}}"
                      style={{if col.width (hash width=col.width)}}
                      scope="col"
                    >
                      {{#if col.sortable}}
                        <button
                          type="button"
                          class="data-table__sort-btn {{if (eq this.sortField col.key) "data-table__sort-btn--active"}}"
                          {{on "click" (fn this.handleSort col.key)}}
                        >
                          {{col.label}}
                          {{#if (eq this.sortField col.key)}}
                            <span class="icon icon--{{if (eq this.sortDirection "asc") "sort-asc" "sort-desc"}}" aria-hidden="true"></span>
                          {{/if}}
                        </button>
                      {{else}}
                        {{col.label}}
                      {{/if}}
                    </th>
                  {{/if}}
                {{/each}}
                <th class="data-table__header data-table__header--actions" scope="col">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="data-table__body">
              {{#each this.paginatedUsers as |user|}}
                <tr class="data-table__row {{if (eq user.id this.userToEdit.id) "data-table__row--editing"}}">
                  <td class="data-table__cell data-table__cell--checkbox">
                    <input
                      type="checkbox"
                      checked={{this.selectedUsers.has user.id}}
                      aria-label="Select {{user.displayName}}"
                      {{on "change" (fn this.toggleUserSelection user.id)}}
                    />
                  </td>
                  <td class="data-table__cell">
                    <div class="user-management__user-cell">
                      <Avatar
                        @src={{user.avatarUrl}}
                        @alt={{user.displayName}}
                        @size="sm"
                        @status={{if user.isActive "online" "offline"}}
                      />
                      <div class="user-management__user-info">
                        <span class="user-management__user-name">{{user.displayName}}</span>
                        <span class="user-management__user-title">{{user.title}}</span>
                      </div>
                    </div>
                  </td>
                  <td class="data-table__cell">
                    <a href="mailto:{{user.email}}" class="user-management__email">{{user.email}}</a>
                  </td>
                  <td class="data-table__cell data-table__cell--center">
                    <Badge
                      @label={{user.role}}
                      @variant={{if (eq user.role "admin") "primary"
                        (if (eq user.role "super_admin") "danger"
                          (if (eq user.role "moderator") "warning" "default"))}}
                      @size="sm"
                    />
                  </td>
                  <td class="data-table__cell">{{user.department}}</td>
                  <td class="data-table__cell data-table__cell--center">
                    {{#if user.isActive}}
                      <Badge @label="Active" @variant="success" @size="sm" />
                    {{else}}
                      <Badge @label="Inactive" @variant="danger" @size="sm" />
                    {{/if}}
                  </td>
                  <td class="data-table__cell data-table__cell--actions">
                    <div class="user-management__row-actions">
                      <button
                        type="button"
                        class="btn btn--icon btn--sm"
                        aria-label="Edit {{user.displayName}}"
                      >
                        <span class="icon icon--edit" aria-hidden="true"></span>
                      </button>
                      {{#if this.canDeleteUsers}}
                        <button
                          type="button"
                          class="btn btn--icon btn--sm btn--danger"
                          aria-label="Delete {{user.displayName}}"
                          {{on "click" (fn this.openDeleteModal user)}}
                        >
                          <span class="icon icon--trash" aria-hidden="true"></span>
                        </button>
                      {{/if}}
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>

          <Pagination
            @meta={{this.paginationMeta}}
            @onPageChange={{this.handlePageChange}}
            @onPerPageChange={{this.handlePerPageChange}}
            @showPerPage={{true}}
          />
        {{else}}
          <EmptyState
            @icon="users"
            @title="No users found"
            @description="Try adjusting your search or filter criteria."
          />
        {{/if}}
      </div>

      <ModalDialog
        @title="Invite New User"
        @isOpen={{this.isInviteModalOpen}}
        @size="md"
        @closable={{true}}
        @confirmLabel="Send Invitation"
        @cancelLabel="Cancel"
        @onClose={{this.closeInviteModal}}
        @onConfirm={{this.handleInvite}}
      >
        <div class="invite-form">
          <div class="invite-form__field">
            <label class="invite-form__label" for="invite-email">Email Address</label>
            <input
              type="email"
              id="invite-email"
              class="invite-form__input"
              placeholder="user@example.com"
              value={{this.inviteEmail}}
              required
              {{on "input" this.handleSearch}}
            />
          </div>
          <div class="invite-form__field">
            <label class="invite-form__label" for="invite-role">Role</label>
            <select id="invite-role" class="invite-form__select">
              {{#each this.roleOptions as |roleOpt|}}
                <option value={{roleOpt.value}} selected={{eq roleOpt.value this.inviteRole}}>
                  {{roleOpt.label}}
                </option>
              {{/each}}
            </select>
          </div>
          <p class="invite-form__hint">
            An invitation email will be sent to the provided address with instructions to set up their account.
          </p>
        </div>
      </ModalDialog>

      <ModalDialog
        @title="Delete User"
        @isOpen={{this.isDeleteModalOpen}}
        @size="sm"
        @closable={{true}}
        @isDangerous={{true}}
        @confirmLabel="Delete User"
        @cancelLabel="Cancel"
        @onClose={{this.closeDeleteModal}}
        @onConfirm={{this.handleDelete}}
      >
        {{#if this.userToDelete}}
          <div class="delete-confirmation">
            <p class="delete-confirmation__message">
              Are you sure you want to delete the user
              <strong>{{this.userToDelete.displayName}}</strong>?
              This action cannot be undone.
            </p>
            <div class="delete-confirmation__user-info">
              <Avatar
                @src={{this.userToDelete.avatarUrl}}
                @alt={{this.userToDelete.displayName}}
                @size="md"
              />
              <div class="delete-confirmation__details">
                <span class="delete-confirmation__name">{{this.userToDelete.displayName}}</span>
                <span class="delete-confirmation__email">{{this.userToDelete.email}}</span>
                <Badge @label={{this.userToDelete.role}} @variant="default" @size="sm" />
              </div>
            </div>
          </div>
        {{/if}}
      </ModalDialog>

      {{yield}}
    </section>
  </template>
}

// ─── Notification Manager Component ─────────────────────────────────────────

interface NotificationManagerSignature {
  Args: {
    notifications: NotificationItem[];
    onDismiss: (id: string) => void;
    onDismissAll: () => void;
    onMarkRead: (id: string) => void;
    onMarkAllRead: () => void;
    onActionClick: (notificationId: string, actionIndex: number) => void;
  };
}

class NotificationManager extends Component<NotificationManagerSignature> {
  @tracked declare filterType: Nullable<NotificationType>;
  @tracked declare showUnreadOnly: boolean;
  @tracked declare isExpanded: boolean;
  @tracked declare searchQuery: string;

  constructor(owner: unknown, args: NotificationManagerSignature['Args']) {
    super(owner, args);
    this.filterType = null;
    this.showUnreadOnly = false;
    this.isExpanded = true;
    this.searchQuery = '';
  }

  get filteredNotifications(): NotificationItem[] {
    let notifications = [...this.args.notifications];

    if (this.showUnreadOnly) {
      notifications = notifications.filter((n) => !n.isRead);
    }

    if (this.filterType) {
      notifications = notifications.filter((n) => n.type === this.filterType);
    }

    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      notifications = notifications.filter(
        (n) =>
          n.title.toLowerCase().includes(query) ||
          n.message.toLowerCase().includes(query),
      );
    }

    return notifications.sort((a, b) => b.priority - a.priority);
  }

  get unreadCount(): number {
    return this.args.notifications.filter((n) => !n.isRead).length;
  }

  get groupedNotifications(): Record<string, NotificationItem[]> {
    const groups: Record<string, NotificationItem[]> = {};
    for (const notification of this.filteredNotifications) {
      const category = notification.category || 'General';
      if (!groups[category]) {
        groups[category] = [];
      }
      groups[category].push(notification);
    }
    return groups;
  }

  get notificationTypeFilters(): Array<{ type: NotificationType; label: string; count: number }> {
    return [
      { type: NotificationType.Info, label: 'Info', count: this.args.notifications.filter((n) => n.type === NotificationType.Info).length },
      { type: NotificationType.Warning, label: 'Warnings', count: this.args.notifications.filter((n) => n.type === NotificationType.Warning).length },
      { type: NotificationType.Error, label: 'Errors', count: this.args.notifications.filter((n) => n.type === NotificationType.Error).length },
      { type: NotificationType.Success, label: 'Success', count: this.args.notifications.filter((n) => n.type === NotificationType.Success).length },
    ];
  }

  @action
  setFilterType(type: Nullable<NotificationType>): void {
    this.filterType = type;
  }

  @action
  toggleUnreadOnly(): void {
    this.showUnreadOnly = !this.showUnreadOnly;
  }

  @action
  toggleExpanded(): void {
    this.isExpanded = !this.isExpanded;
  }

  @action
  handleSearchInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.searchQuery = target.value;
  }

  <template>
    <section class="notification-manager" aria-label="Notifications">
      <div class="notification-manager__header">
        <div class="notification-manager__title-row">
          <h2 class="notification-manager__title">
            Notifications
            {{#if this.unreadCount}}
              <span class="notification-manager__unread-badge">{{this.unreadCount}}</span>
            {{/if}}
          </h2>
          <div class="notification-manager__header-actions">
            <button
              type="button"
              class="btn btn--sm btn--secondary"
              {{on "click" this.args.onMarkAllRead}}
            >
              Mark All Read
            </button>
            <button
              type="button"
              class="btn btn--sm btn--secondary"
              {{on "click" this.args.onDismissAll}}
            >
              Clear All
            </button>
            <button
              type="button"
              class="btn btn--icon btn--sm"
              aria-label={{if this.isExpanded "Collapse" "Expand"}}
              {{on "click" this.toggleExpanded}}
            >
              <span class="icon icon--{{if this.isExpanded "chevron-up" "chevron-down"}}" aria-hidden="true"></span>
            </button>
          </div>
        </div>

        {{#if this.isExpanded}}
          <div class="notification-manager__controls">
            <div class="notification-manager__search">
              <input
                type="search"
                class="notification-manager__search-input"
                placeholder="Search notifications..."
                value={{this.searchQuery}}
                {{on "input" this.handleSearchInput}}
              />
            </div>
            <div class="notification-manager__filters">
              <button
                type="button"
                class="btn btn--sm {{unless this.filterType "btn--active"}}"
                {{on "click" (fn this.setFilterType null)}}
              >
                All
              </button>
              {{#each this.notificationTypeFilters as |filter|}}
                <button
                  type="button"
                  class="btn btn--sm {{if (eq this.filterType filter.type) "btn--active"}}"
                  {{on "click" (fn this.setFilterType filter.type)}}
                >
                  {{filter.label}}
                  <span class="notification-manager__filter-count">({{filter.count}})</span>
                </button>
              {{/each}}
              <label class="notification-manager__unread-toggle">
                <input
                  type="checkbox"
                  checked={{this.showUnreadOnly}}
                  {{on "change" this.toggleUnreadOnly}}
                />
                Unread only
              </label>
            </div>
          </div>
        {{/if}}
      </div>

      {{#if this.isExpanded}}
        <div class="notification-manager__body">
          {{#if this.filteredNotifications.length}}
            <div class="notification-manager__list" role="log" aria-live="polite">
              {{#each this.filteredNotifications as |notification|}}
                <NotificationToast
                  @notification={{notification}}
                  @onDismiss={{this.args.onDismiss}}
                  @onMarkRead={{this.args.onMarkRead}}
                  @onActionClick={{this.args.onActionClick}}
                />
              {{/each}}
            </div>
          {{else}}
            <EmptyState
              @icon="bell-off"
              @title="No notifications"
              @description={{if this.showUnreadOnly "You have no unread notifications." "No notifications match your current filters."}}
            />
          {{/if}}
        </div>
      {{/if}}
    </section>
  </template>
}

// ─── Main Dashboard Component (Default Export) ──────────────────────────────

interface DashboardSignature {
  Args: {
    currentUser: UserProfile;
    users: UserProfile[];
    userStats: UserStats;
    notifications: NotificationItem[];
    analytics: AnalyticsDashboard;
    navItems: NavItem[];
    billingPlans: BillingPlan[];
    currentPlanId: string;
    invoices: Invoice[];
    settingsCategories: SettingsCategory[];
    breadcrumbs: BreadcrumbItem[];
    onUpdateUser: (userId: UserId, data: DeepPartial<UserProfile>) => Promise<void>;
    onDeleteUser: (userId: UserId) => Promise<void>;
    onInviteUser: (email: string, role: UserRole) => Promise<void>;
    onDismissNotification: (id: string) => void;
    onDismissAllNotifications: () => void;
    onMarkNotificationRead: (id: string) => void;
    onMarkAllNotificationsRead: () => void;
    onNotificationAction: (notificationId: string, actionIndex: number) => void;
    onNavItemClick: (item: NavItem) => void;
    onToggleSidebar: () => void;
    onSelectPlan: (planId: string) => void;
    onSaveSettings: (data: SettingsFormData) => Promise<void>;
    onTabChange: (tabId: TabId) => void;
    onLogout: () => void;
  };
  Blocks: {
    default?: [];
  };
}

export default class DashboardApp extends Component<DashboardSignature> {
  @tracked declare activeTab: TabId;
  @tracked declare sidebarCollapsed: boolean;
  @tracked declare isUserMenuOpen: boolean;
  @tracked declare isSearchOpen: boolean;
  @tracked declare globalSearch: string;
  @tracked declare isSettingsSaving: boolean;
  @tracked declare settingsActiveCategory: string;
  @tracked declare isProfileModalOpen: boolean;
  @tracked declare isDarkMode: boolean;
  @tracked declare chartLoading: boolean;
  @tracked declare selectedInvoiceId: Nullable<string>;

  constructor(owner: unknown, args: DashboardSignature['Args']) {
    super(owner, args);
    this.activeTab = TabId.Overview;
    this.sidebarCollapsed = false;
    this.isUserMenuOpen = false;
    this.isSearchOpen = false;
    this.globalSearch = '';
    this.isSettingsSaving = false;
    this.settingsActiveCategory = '';
    this.isProfileModalOpen = false;
    this.isDarkMode = false;
    this.chartLoading = false;
    this.selectedInvoiceId = null;
  }

  get dashboardTabs(): Array<{ id: string; label: string; icon: string; badge?: string | number }> {
    return [
      { id: TabId.Overview, label: 'Overview', icon: 'home' },
      { id: TabId.Analytics, label: 'Analytics', icon: 'chart-bar' },
      { id: TabId.Users, label: 'Users', icon: 'users', badge: this.args.users.length },
      { id: TabId.Notifications, label: 'Notifications', icon: 'bell', badge: this.unreadNotificationCount },
      { id: TabId.Billing, label: 'Billing', icon: 'credit-card' },
      { id: TabId.Settings, label: 'Settings', icon: 'cog' },
    ];
  }

  get unreadNotificationCount(): number {
    return this.args.notifications.filter((n) => !n.isRead).length;
  }

  get currentPlan(): Nullable<BillingPlan> {
    return this.args.billingPlans.find((p) => p.id === this.args.currentPlanId) ?? null;
  }

  get recentInvoices(): Invoice[] {
    return [...this.args.invoices]
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, 5);
  }

  get overviewMetrics(): AnalyticsMetric[] {
    return this.args.analytics.metrics.slice(0, 4);
  }

  get userInitials(): string {
    const first = this.args.currentUser.firstName.charAt(0).toUpperCase();
    const last = this.args.currentUser.lastName.charAt(0).toUpperCase();
    return `${first}${last}`;
  }

  get activeSettingsCategory(): Nullable<SettingsCategory> {
    return this.args.settingsCategories.find((c) => c.id === this.settingsActiveCategory) ?? this.args.settingsCategories[0] ?? null;
  }

  get pendingInvoiceCount(): number {
    return this.args.invoices.filter((i) => i.status === 'pending' || i.status === 'overdue').length;
  }

  @action
  handleTabChange(tabId: string): void {
    this.activeTab = tabId as TabId;
    this.args.onTabChange(tabId as TabId);
  }

  @action
  toggleSidebar(): void {
    this.sidebarCollapsed = !this.sidebarCollapsed;
    this.args.onToggleSidebar();
  }

  @action
  toggleUserMenu(): void {
    this.isUserMenuOpen = !this.isUserMenuOpen;
  }

  @action
  closeUserMenu(): void {
    this.isUserMenuOpen = false;
  }

  @action
  toggleSearch(): void {
    this.isSearchOpen = !this.isSearchOpen;
    if (!this.isSearchOpen) {
      this.globalSearch = '';
    }
  }

  @action
  handleGlobalSearch(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.globalSearch = target.value;
  }

  @action
  handleSettingsCategoryChange(categoryId: string): void {
    this.settingsActiveCategory = categoryId;
  }

  @action
  openProfileModal(): void {
    this.isProfileModalOpen = true;
    this.isUserMenuOpen = false;
  }

  @action
  closeProfileModal(): void {
    this.isProfileModalOpen = false;
  }

  @action
  toggleDarkMode(): void {
    this.isDarkMode = !this.isDarkMode;
  }

  @action
  handleSelectInvoice(invoiceId: string): void {
    this.selectedInvoiceId = invoiceId;
  }

  @action
  handleFieldInput(fieldName: string, _event: Event): void {
    void fieldName;
  }

  @action
  handleFieldBlur(fieldName: string): void {
    void fieldName;
  }

  <template>
    <div class="dashboard {{if this.isDarkMode "dashboard--dark"}} {{if this.sidebarCollapsed "dashboard--sidebar-collapsed"}}">
      <SidebarNav
        @items={{this.args.navItems}}
        @collapsed={{this.sidebarCollapsed}}
        @onToggle={{this.toggleSidebar}}
        @onItemClick={{this.args.onNavItemClick}}
      />

      <div class="dashboard__main">
        <header class="dashboard__topbar">
          <div class="dashboard__topbar-left">
            <Breadcrumbs @items={{this.args.breadcrumbs}} />
          </div>
          <div class="dashboard__topbar-center">
            {{#if this.isSearchOpen}}
              <div class="dashboard__global-search">
                <span class="icon icon--search" aria-hidden="true"></span>
                <input
                  type="search"
                  class="dashboard__global-search-input"
                  placeholder="Search everything..."
                  value={{this.globalSearch}}
                  autofocus
                  {{on "input" this.handleGlobalSearch}}
                />
                <button
                  type="button"
                  class="btn btn--icon btn--sm"
                  aria-label="Close search"
                  {{on "click" this.toggleSearch}}
                >
                  <span class="icon icon--x" aria-hidden="true"></span>
                </button>
              </div>
            {{/if}}
          </div>
          <div class="dashboard__topbar-right">
            <button
              type="button"
              class="btn btn--icon"
              aria-label="Search"
              {{on "click" this.toggleSearch}}
            >
              <span class="icon icon--search" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="btn btn--icon"
              aria-label="Toggle dark mode"
              {{on "click" this.toggleDarkMode}}
            >
              <span class="icon icon--{{if this.isDarkMode "sun" "moon"}}" aria-hidden="true"></span>
            </button>
            <button
              type="button"
              class="btn btn--icon dashboard__notification-btn"
              aria-label="Notifications ({{this.unreadNotificationCount}} unread)"
            >
              <span class="icon icon--bell" aria-hidden="true"></span>
              {{#if this.unreadNotificationCount}}
                <span class="dashboard__notification-badge">{{this.unreadNotificationCount}}</span>
              {{/if}}
            </button>
            <div class="dashboard__user-menu-wrapper">
              <button
                type="button"
                class="dashboard__user-trigger"
                aria-expanded={{if this.isUserMenuOpen "true" "false"}}
                aria-haspopup="true"
                {{on "click" this.toggleUserMenu}}
              >
                <Avatar
                  @src={{this.args.currentUser.avatarUrl}}
                  @alt={{this.args.currentUser.displayName}}
                  @size="sm"
                  @initials={{this.userInitials}}
                  @status="online"
                />
                <span class="dashboard__user-name">{{this.args.currentUser.displayName}}</span>
                <span class="icon icon--chevron-down" aria-hidden="true"></span>
              </button>
              {{#if this.isUserMenuOpen}}
                <div class="dashboard__user-dropdown" role="menu">
                  <div class="dashboard__user-dropdown-header">
                    <span class="dashboard__user-dropdown-name">{{this.args.currentUser.displayName}}</span>
                    <span class="dashboard__user-dropdown-email">{{this.args.currentUser.email}}</span>
                    <Badge @label={{this.args.currentUser.role}} @variant="primary" @size="sm" />
                  </div>
                  <hr class="dashboard__user-dropdown-divider" />
                  <button
                    type="button"
                    class="dashboard__user-dropdown-item"
                    role="menuitem"
                    {{on "click" this.openProfileModal}}
                  >
                    <span class="icon icon--user" aria-hidden="true"></span>
                    My Profile
                  </button>
                  <button type="button" class="dashboard__user-dropdown-item" role="menuitem">
                    <span class="icon icon--cog" aria-hidden="true"></span>
                    Account Settings
                  </button>
                  <button type="button" class="dashboard__user-dropdown-item" role="menuitem">
                    <span class="icon icon--key" aria-hidden="true"></span>
                    API Keys
                  </button>
                  <hr class="dashboard__user-dropdown-divider" />
                  <button
                    type="button"
                    class="dashboard__user-dropdown-item dashboard__user-dropdown-item--danger"
                    role="menuitem"
                    {{on "click" this.args.onLogout}}
                  >
                    <span class="icon icon--logout" aria-hidden="true"></span>
                    Sign Out
                  </button>
                </div>
              {{/if}}
            </div>
          </div>
        </header>

        <div class="dashboard__content">
          <TabBar
            @tabs={{this.dashboardTabs}}
            @activeTabId={{this.activeTab}}
            @onTabChange={{this.handleTabChange}}
            @variant="underline"
          />

          <div class="dashboard__tab-panels">
            {{!-- Overview Tab --}}
            {{#if (eq this.activeTab "overview")}}
              <div class="dashboard__panel" id="panel-overview" role="tabpanel" aria-labelledby="tab-overview">
                <div class="dashboard__overview">
                  <div class="dashboard__metrics-grid">
                    {{#each this.overviewMetrics as |metric|}}
                      <MetricCard
                        @title={{metric.name}}
                        @value={{metric.value}}
                        @previousValue={{metric.previousValue}}
                        @changePercent={{metric.changePercent}}
                        @trend={{metric.trend}}
                        @unit={{metric.unit}}
                      />
                    {{/each}}
                  </div>

                  <div class="dashboard__overview-charts">
                    {{#each this.args.analytics.charts as |chart|}}
                      <ChartPlaceholder @config={{chart}} @loading={{this.chartLoading}} />
                    {{/each}}
                  </div>

                  <div class="dashboard__overview-widgets">
                    <div class="dashboard__widget dashboard__widget--recent-activity">
                      <h3 class="dashboard__widget-title">Recent Activity</h3>
                      <div class="dashboard__widget-body">
                        {{#each this.args.notifications as |notification|}}
                          {{#unless notification.isDismissed}}
                            <div class="dashboard__activity-item">
                              <div class="dashboard__activity-icon">
                                {{#if (eq notification.type "info")}}
                                  <span class="icon icon--info-circle" aria-hidden="true"></span>
                                {{else if (eq notification.type "success")}}
                                  <span class="icon icon--check-circle" aria-hidden="true"></span>
                                {{else if (eq notification.type "warning")}}
                                  <span class="icon icon--exclamation-triangle" aria-hidden="true"></span>
                                {{else}}
                                  <span class="icon icon--x-circle" aria-hidden="true"></span>
                                {{/if}}
                              </div>
                              <div class="dashboard__activity-content">
                                <span class="dashboard__activity-title">{{notification.title}}</span>
                                <span class="dashboard__activity-message">{{notification.message}}</span>
                              </div>
                              {{#if notification.sender}}
                                <Avatar
                                  @src={{notification.sender.avatarUrl}}
                                  @alt={{notification.sender.displayName}}
                                  @size="xs"
                                />
                              {{/if}}
                            </div>
                          {{/unless}}
                        {{/each}}
                      </div>
                    </div>

                    <div class="dashboard__widget dashboard__widget--quick-stats">
                      <h3 class="dashboard__widget-title">Team Overview</h3>
                      <div class="dashboard__widget-body">
                        <div class="dashboard__quick-stat">
                          <span class="dashboard__quick-stat-label">Total Members</span>
                          <span class="dashboard__quick-stat-value">{{this.args.userStats.totalUsers}}</span>
                        </div>
                        <div class="dashboard__quick-stat">
                          <span class="dashboard__quick-stat-label">Active Now</span>
                          <span class="dashboard__quick-stat-value">{{this.args.userStats.activeUsers}}</span>
                        </div>
                        <div class="dashboard__quick-stat">
                          <span class="dashboard__quick-stat-label">Pending Invoices</span>
                          <span class="dashboard__quick-stat-value">{{this.pendingInvoiceCount}}</span>
                        </div>
                        {{#if this.currentPlan}}
                          <div class="dashboard__quick-stat">
                            <span class="dashboard__quick-stat-label">Current Plan</span>
                            <span class="dashboard__quick-stat-value">{{this.currentPlan.name}}</span>
                          </div>
                        {{/if}}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            {{/if}}

            {{!-- Analytics Tab --}}
            {{#if (eq this.activeTab "analytics")}}
              <div class="dashboard__panel" id="panel-analytics" role="tabpanel" aria-labelledby="tab-analytics">
                <div class="dashboard__analytics">
                  <div class="dashboard__analytics-header">
                    <h3 class="dashboard__section-title">Analytics Dashboard</h3>
                    <div class="dashboard__analytics-date-range">
                      <span class="dashboard__analytics-date">
                        Data from analytics period
                      </span>
                    </div>
                  </div>

                  <div class="dashboard__metrics-grid">
                    {{#each this.args.analytics.metrics as |metric|}}
                      <MetricCard
                        @title={{metric.name}}
                        @value={{metric.value}}
                        @previousValue={{metric.previousValue}}
                        @changePercent={{metric.changePercent}}
                        @trend={{metric.trend}}
                        @unit={{metric.unit}}
                        @icon="chart-bar"
                      />
                    {{/each}}
                  </div>

                  <div class="dashboard__analytics-charts">
                    {{#each this.args.analytics.charts as |chart|}}
                      <div class="dashboard__analytics-chart-wrapper">
                        <ChartPlaceholder @config={{chart}} @loading={{this.chartLoading}} />
                      </div>
                    {{/each}}
                  </div>
                </div>
              </div>
            {{/if}}

            {{!-- Users Tab --}}
            {{#if (eq this.activeTab "users")}}
              <div class="dashboard__panel" id="panel-users" role="tabpanel" aria-labelledby="tab-users">
                <UserManagementPanel
                  @users={{this.args.users}}
                  @currentUser={{this.args.currentUser}}
                  @stats={{this.args.userStats}}
                  @onUpdateUser={{this.args.onUpdateUser}}
                  @onDeleteUser={{this.args.onDeleteUser}}
                  @onInviteUser={{this.args.onInviteUser}}
                />
              </div>
            {{/if}}

            {{!-- Notifications Tab --}}
            {{#if (eq this.activeTab "notifications")}}
              <div class="dashboard__panel" id="panel-notifications" role="tabpanel" aria-labelledby="tab-notifications">
                <NotificationManager
                  @notifications={{this.args.notifications}}
                  @onDismiss={{this.args.onDismissNotification}}
                  @onDismissAll={{this.args.onDismissAllNotifications}}
                  @onMarkRead={{this.args.onMarkNotificationRead}}
                  @onMarkAllRead={{this.args.onMarkAllNotificationsRead}}
                  @onActionClick={{this.args.onNotificationAction}}
                />
              </div>
            {{/if}}

            {{!-- Billing Tab --}}
            {{#if (eq this.activeTab "billing")}}
              <div class="dashboard__panel" id="panel-billing" role="tabpanel" aria-labelledby="tab-billing">
                <div class="dashboard__billing">
                  <div class="dashboard__billing-header">
                    <h3 class="dashboard__section-title">Billing & Plans</h3>
                    {{#if this.currentPlan}}
                      <div class="dashboard__current-plan">
                        <span class="dashboard__current-plan-label">Current Plan:</span>
                        <Badge @label={{this.currentPlan.name}} @variant="primary" />
                        <span class="dashboard__current-plan-price">
                          {{this.currentPlan.currency}}{{this.currentPlan.price}}/{{this.currentPlan.interval}}
                        </span>
                      </div>
                    {{/if}}
                  </div>

                  <div class="dashboard__billing-plans">
                    {{#each this.args.billingPlans as |plan|}}
                      <BillingPlanCard
                        @plan={{plan}}
                        @isCurrentPlan={{eq plan.id this.args.currentPlanId}}
                        @onSelect={{this.args.onSelectPlan}}
                      />
                    {{/each}}
                  </div>

                  <div class="dashboard__invoices">
                    <h3 class="dashboard__section-title">Recent Invoices</h3>
                    {{#if this.recentInvoices.length}}
                      <table class="data-table" role="grid" aria-label="Invoices">
                        <thead class="data-table__head">
                          <tr>
                            <th scope="col">Invoice #</th>
                            <th scope="col">Amount</th>
                            <th scope="col">Status</th>
                            <th scope="col">Due Date</th>
                            <th scope="col">Actions</th>
                          </tr>
                        </thead>
                        <tbody class="data-table__body">
                          {{#each this.recentInvoices as |invoice|}}
                            <tr class="data-table__row {{if (eq this.selectedInvoiceId invoice.id) "data-table__row--selected"}}">
                              <td class="data-table__cell">{{invoice.number}}</td>
                              <td class="data-table__cell">
                                {{invoice.currency}} {{invoice.amount}}
                              </td>
                              <td class="data-table__cell">
                                <Badge
                                  @label={{invoice.status}}
                                  @variant={{if (eq invoice.status "paid") "success"
                                    (if (eq invoice.status "pending") "warning"
                                      (if (eq invoice.status "overdue") "danger" "default"))}}
                                  @size="sm"
                                />
                              </td>
                              <td class="data-table__cell">
                                Due date
                              </td>
                              <td class="data-table__cell data-table__cell--actions">
                                <button
                                  type="button"
                                  class="btn btn--sm btn--secondary"
                                  {{on "click" (fn this.handleSelectInvoice invoice.id)}}
                                >
                                  View
                                </button>
                                <button type="button" class="btn btn--sm btn--secondary">
                                  Download
                                </button>
                              </td>
                            </tr>
                          {{/each}}
                        </tbody>
                      </table>
                    {{else}}
                      <EmptyState
                        @icon="receipt"
                        @title="No invoices yet"
                        @description="Your invoices will appear here once you subscribe to a plan."
                      />
                    {{/if}}
                  </div>
                </div>
              </div>
            {{/if}}

            {{!-- Settings Tab --}}
            {{#if (eq this.activeTab "settings")}}
              <div class="dashboard__panel" id="panel-settings" role="tabpanel" aria-labelledby="tab-settings">
                <div class="dashboard__settings">
                  <div class="dashboard__settings-header">
                    <h3 class="dashboard__section-title">Settings</h3>
                  </div>

                  <div class="dashboard__settings-layout">
                    <nav class="dashboard__settings-nav" aria-label="Settings categories">
                      <ul class="dashboard__settings-nav-list">
                        {{#each this.args.settingsCategories as |category|}}
                          <li class="dashboard__settings-nav-item">
                            <button
                              type="button"
                              class="dashboard__settings-nav-link {{if (eq this.settingsActiveCategory category.id) "dashboard__settings-nav-link--active"}}"
                              {{on "click" (fn this.handleSettingsCategoryChange category.id)}}
                            >
                              <span class="icon icon--{{category.icon}}" aria-hidden="true"></span>
                              {{category.label}}
                              {{#if category.requiresAdmin}}
                                <Badge @label="Admin" @variant="warning" @size="sm" />
                              {{/if}}
                            </button>
                          </li>
                        {{/each}}
                      </ul>
                    </nav>

                    <div class="dashboard__settings-content">
                      {{#if this.activeSettingsCategory}}
                        <div class="dashboard__settings-category">
                          <h4 class="dashboard__settings-category-title">
                            {{this.activeSettingsCategory.label}}
                          </h4>

                          {{#each this.activeSettingsCategory.sections as |section|}}
                            <div class="dashboard__settings-section {{if section.collapsed "dashboard__settings-section--collapsed"}}">
                              <div class="dashboard__settings-section-header">
                                <h5 class="dashboard__settings-section-title">{{section.title}}</h5>
                                {{#if section.description}}
                                  <p class="dashboard__settings-section-desc">{{section.description}}</p>
                                {{/if}}
                              </div>
                              {{#unless section.collapsed}}
                                <div class="dashboard__settings-section-fields">
                                  {{#each section.fields as |field|}}
                                    <FormFieldComponent
                                      @field={{field}}
                                      @onInput={{this.handleFieldInput}}
                                      @onBlur={{this.handleFieldBlur}}
                                    />
                                  {{/each}}
                                </div>
                              {{/unless}}
                            </div>
                          {{/each}}

                          <div class="dashboard__settings-actions">
                            <button type="button" class="btn btn--secondary">
                              Reset to Defaults
                            </button>
                            <button
                              type="button"
                              class="btn btn--primary"
                              disabled={{this.isSettingsSaving}}
                            >
                              {{#if this.isSettingsSaving}}
                                <LoadingSpinner @size="sm" />
                                Saving...
                              {{else}}
                                Save Changes
                              {{/if}}
                            </button>
                          </div>
                        </div>
                      {{else}}
                        <EmptyState
                          @icon="cog"
                          @title="Select a category"
                          @description="Choose a settings category from the sidebar to get started."
                        />
                      {{/if}}
                    </div>
                  </div>
                </div>
              </div>
            {{/if}}
          </div>
        </div>

        <footer class="dashboard__footer">
          <div class="dashboard__footer-left">
            <span class="dashboard__footer-copyright">2026 Dashboard App. All rights reserved.</span>
          </div>
          <div class="dashboard__footer-right">
            <a href="/privacy" class="dashboard__footer-link">Privacy Policy</a>
            <a href="/terms" class="dashboard__footer-link">Terms of Service</a>
            <a href="/support" class="dashboard__footer-link">Support</a>
          </div>
        </footer>
      </div>

      {{!-- Profile Modal --}}
      <ModalDialog
        @title="My Profile"
        @isOpen={{this.isProfileModalOpen}}
        @size="lg"
        @closable={{true}}
        @confirmLabel="Save Profile"
        @cancelLabel="Close"
        @onClose={{this.closeProfileModal}}
      >
        <div class="profile-modal">
          <div class="profile-modal__header">
            <Avatar
              @src={{this.args.currentUser.avatarUrl}}
              @alt={{this.args.currentUser.displayName}}
              @size="xl"
              @initials={{this.userInitials}}
              @status="online"
            />
            <div class="profile-modal__info">
              <h3 class="profile-modal__name">{{this.args.currentUser.displayName}}</h3>
              <p class="profile-modal__email">{{this.args.currentUser.email}}</p>
              <div class="profile-modal__badges">
                <Badge @label={{this.args.currentUser.role}} @variant="primary" />
                <Badge @label={{this.args.currentUser.department}} @variant="default" />
              </div>
            </div>
          </div>

          <div class="profile-modal__details">
            <div class="profile-modal__section">
              <h4 class="profile-modal__section-title">Personal Information</h4>
              <div class="profile-modal__fields">
                <div class="profile-modal__field">
                  <span class="profile-modal__field-label">First Name</span>
                  <span class="profile-modal__field-value">{{this.args.currentUser.firstName}}</span>
                </div>
                <div class="profile-modal__field">
                  <span class="profile-modal__field-label">Last Name</span>
                  <span class="profile-modal__field-value">{{this.args.currentUser.lastName}}</span>
                </div>
                <div class="profile-modal__field">
                  <span class="profile-modal__field-label">Title</span>
                  <span class="profile-modal__field-value">{{this.args.currentUser.title}}</span>
                </div>
                <div class="profile-modal__field">
                  <span class="profile-modal__field-label">Phone</span>
                  <span class="profile-modal__field-value">
                    {{if this.args.currentUser.phone this.args.currentUser.phone "Not provided"}}
                  </span>
                </div>
              </div>
            </div>

            <div class="profile-modal__section">
              <h4 class="profile-modal__section-title">Address</h4>
              <div class="profile-modal__address">
                <p>{{this.args.currentUser.address.street}}</p>
                <p>{{this.args.currentUser.address.city}}, {{this.args.currentUser.address.state}} {{this.args.currentUser.address.zipCode}}</p>
                <p>{{this.args.currentUser.address.country}}</p>
              </div>
            </div>

            <div class="profile-modal__section">
              <h4 class="profile-modal__section-title">Preferences</h4>
              <div class="profile-modal__preferences">
                <div class="profile-modal__pref">
                  <span class="profile-modal__pref-label">Theme</span>
                  <Badge @label={{this.args.currentUser.preferences.theme}} @variant="default" @size="sm" />
                </div>
                <div class="profile-modal__pref">
                  <span class="profile-modal__pref-label">Language</span>
                  <span class="profile-modal__pref-value">{{this.args.currentUser.preferences.language}}</span>
                </div>
                <div class="profile-modal__pref">
                  <span class="profile-modal__pref-label">Timezone</span>
                  <span class="profile-modal__pref-value">{{this.args.currentUser.preferences.timezone}}</span>
                </div>
                <div class="profile-modal__pref">
                  <span class="profile-modal__pref-label">Email Notifications</span>
                  <Badge
                    @label={{if this.args.currentUser.preferences.emailNotifications "Enabled" "Disabled"}}
                    @variant={{if this.args.currentUser.preferences.emailNotifications "success" "default"}}
                    @size="sm"
                  />
                </div>
                <div class="profile-modal__pref">
                  <span class="profile-modal__pref-label">Push Notifications</span>
                  <Badge
                    @label={{if this.args.currentUser.preferences.pushNotifications "Enabled" "Disabled"}}
                    @variant={{if this.args.currentUser.preferences.pushNotifications "success" "default"}}
                    @size="sm"
                  />
                </div>
              </div>
            </div>

            <div class="profile-modal__section">
              <h4 class="profile-modal__section-title">Tags</h4>
              <div class="profile-modal__tags">
                {{#each this.args.currentUser.tags as |tag|}}
                  <Badge @label={{tag}} @variant="info" @size="sm" @removable={{true}} />
                {{else}}
                  <span class="profile-modal__no-tags">No tags assigned</span>
                {{/each}}
              </div>
            </div>
          </div>
        </div>
      </ModalDialog>

      {{yield}}
    </div>
  </template>
}
