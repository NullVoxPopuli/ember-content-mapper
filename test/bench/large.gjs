import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, hash, array } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { eq, not, and, or } from 'ember-truth-helpers';
import { modifier } from 'ember-modifier';

// ─── Constants ───────────────────────────────────────────────────────────────

const SORT_ASC = 'asc';
const SORT_DESC = 'desc';
const PAGE_SIZE = 25;
const MAX_PAGES = 100;
const DEFAULT_LOCALE = 'en-US';
const DATE_FORMAT = 'YYYY-MM-DD';
const DEBOUNCE_MS = 300;

const STATUS_ACTIVE = 'active';
const STATUS_INACTIVE = 'inactive';
const STATUS_PENDING = 'pending';
const STATUS_ARCHIVED = 'archived';

const ROLE_ADMIN = 'admin';
const ROLE_EDITOR = 'editor';
const ROLE_VIEWER = 'viewer';
const ROLE_OWNER = 'owner';

const PRIORITY_LOW = 1;
const PRIORITY_MEDIUM = 2;
const PRIORITY_HIGH = 3;
const PRIORITY_CRITICAL = 4;

const NOTIFICATION_TYPES = [
  'info',
  'warning',
  'error',
  'success',
];

const CHART_COLORS = [
  '#3b82f6',
  '#ef4444',
  '#10b981',
  '#f59e0b',
  '#8b5cf6',
  '#ec4899',
  '#06b6d4',
  '#84cc16',
];

const THEME_LIGHT = 'light';
const THEME_DARK = 'dark';
const THEME_AUTO = 'auto';

const SIDEBAR_WIDTH = 260;
const SIDEBAR_COLLAPSED_WIDTH = 64;

const BREAKPOINTS = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  xxl: 1536,
};

// ─── Utility Functions ───────────────────────────────────────────────────────

function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat(DEFAULT_LOCALE, {
    style: 'currency',
    currency,
  }).format(amount);
}

function formatDate(date) {
  if (!date) return '';
  const d = new Date(date);
  return d.toLocaleDateString(DEFAULT_LOCALE, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatDateTime(date) {
  if (!date) return '';
  const d = new Date(date);
  return d.toLocaleString(DEFAULT_LOCALE, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function formatRelativeTime(date) {
  if (!date) return '';
  const now = Date.now();
  const diff = now - new Date(date).getTime();
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 30) return formatDate(date);
  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  if (minutes > 0) return `${minutes}m ago`;
  return 'just now';
}

function truncate(str, length = 100) {
  if (!str) return '';
  if (str.length <= length) return str;
  return str.slice(0, length) + '...';
}

function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function slugify(str) {
  return str
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function debounce(func, wait) {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function groupBy(arr, key) {
  return arr.reduce((groups, item) => {
    const val = item[key];
    groups[val] = groups[val] || [];
    groups[val].push(item);
    return groups;
  }, {});
}

function sortBy(arr, key, direction = SORT_ASC) {
  return [...arr].sort((a, b) => {
    const aVal = a[key];
    const bVal = b[key];
    const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
    return direction === SORT_ASC ? cmp : -cmp;
  });
}

function filterBySearch(items, query, keys) {
  if (!query) return items;
  const lower = query.toLowerCase();
  return items.filter((item) =>
    keys.some((key) => {
      const val = item[key];
      return val && String(val).toLowerCase().includes(lower);
    })
  );
}

function paginate(items, page, perPage = PAGE_SIZE) {
  const start = (page - 1) * perPage;
  return items.slice(start, start + perPage);
}

function getInitials(name) {
  if (!name) return '??';
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

function getStatusColor(status) {
  switch (status) {
    case STATUS_ACTIVE: return 'green';
    case STATUS_INACTIVE: return 'gray';
    case STATUS_PENDING: return 'yellow';
    case STATUS_ARCHIVED: return 'blue';
    default: return 'gray';
  }
}

function getPriorityLabel(priority) {
  switch (priority) {
    case PRIORITY_LOW: return 'Low';
    case PRIORITY_MEDIUM: return 'Medium';
    case PRIORITY_HIGH: return 'High';
    case PRIORITY_CRITICAL: return 'Critical';
    default: return 'Unknown';
  }
}

function getPriorityColor(priority) {
  switch (priority) {
    case PRIORITY_LOW: return 'text-slate-500';
    case PRIORITY_MEDIUM: return 'text-blue-500';
    case PRIORITY_HIGH: return 'text-orange-500';
    case PRIORITY_CRITICAL: return 'text-red-600';
    default: return 'text-gray-400';
  }
}

function computePercentage(current, total) {
  if (!total || total === 0) return 0;
  return Math.round((current / total) * 100);
}

function generateId() {
  return Math.random().toString(36).slice(2, 11);
}

function flattenTree(nodes, depth = 0) {
  let result = [];
  for (const node of nodes) {
    result.push({ ...node, depth });
    if (node.children && node.children.length) {
      result = result.concat(flattenTree(node.children, depth + 1));
    }
  }
  return result;
}

function mergeDefaults(options, defaults) {
  const merged = { ...defaults };
  for (const key of Object.keys(options)) {
    if (options[key] !== undefined) {
      merged[key] = options[key];
    }
  }
  return merged;
}

function buildQueryString(params) {
  return Object.entries(params)
    .filter(([, v]) => v !== null && v !== undefined && v !== '')
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
}

function parseQueryString(qs) {
  const params = {};
  const cleaned = qs.startsWith('?') ? qs.slice(1) : qs;
  for (const pair of cleaned.split('&')) {
    const [key, val] = pair.split('=');
    if (key) {
      params[decodeURIComponent(key)] = decodeURIComponent(val || '');
    }
  }
  return params;
}

function sumBy(arr, key) {
  return arr.reduce((total, item) => total + (Number(item[key]) || 0), 0);
}

function averageBy(arr, key) {
  if (!arr.length) return 0;
  return sumBy(arr, key) / arr.length;
}

function uniqueBy(arr, key) {
  const seen = new Set();
  return arr.filter((item) => {
    const val = item[key];
    if (seen.has(val)) return false;
    seen.add(val);
    return true;
  });
}

function chunk(arr, size) {
  const result = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
}

function pick(obj, keys) {
  const result = {};
  for (const key of keys) {
    if (key in obj) {
      result[key] = obj[key];
    }
  }
  return result;
}

function omit(obj, keys) {
  const result = { ...obj };
  for (const key of keys) {
    delete result[key];
  }
  return result;
}

function isEmpty(value) {
  if (value == null) return true;
  if (typeof value === 'string') return value.trim() === '';
  if (Array.isArray(value)) return value.length === 0;
  if (typeof value === 'object') return Object.keys(value).length === 0;
  return false;
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidUrl(url) {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

// ─── Custom Modifiers ────────────────────────────────────────────────────────

const autoFocus = modifier((element) => {
  element.focus();
});

const onClickOutside = modifier((element, [callback]) => {
  function handleClick(event) {
    if (!element.contains(event.target)) {
      callback();
    }
  }
  document.addEventListener('click', handleClick, true);
  return () => {
    document.removeEventListener('click', handleClick, true);
  };
});

const tooltip = modifier((element, [text]) => {
  element.setAttribute('title', text);
  element.setAttribute('aria-label', text);
});

const resizeObserver = modifier((element, [callback]) => {
  const observer = new ResizeObserver((entries) => {
    for (const entry of entries) {
      callback(entry.contentRect);
    }
  });
  observer.observe(element);
  return () => observer.disconnect();
});

// ─── Template-Only Components ────────────────────────────────────────────────

const LoadingSpinner = <template>
  <div class="loading-spinner-container" role="status" aria-label="Loading">
    <div class="loading-spinner {{@size}}">
      <svg class="animate-spin" viewBox="0 0 24 24" fill="none">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
      </svg>
    </div>
    {{#if @message}}
      <p class="loading-message text-sm text-gray-500 mt-2">{{@message}}</p>
    {{/if}}
  </div>
</template>;

const EmptyState = <template>
  <div class="empty-state flex flex-col items-center justify-center py-12 px-6">
    <div class="empty-state-icon mb-4 text-gray-300">
      {{#if @icon}}
        <span class="text-6xl">{{@icon}}</span>
      {{else}}
        <svg class="w-16 h-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
            d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
      {{/if}}
    </div>
    <h3 class="empty-state-title text-lg font-medium text-gray-900 mb-1">
      {{#if @title}}
        {{@title}}
      {{else}}
        No items found
      {{/if}}
    </h3>
    {{#if @description}}
      <p class="empty-state-description text-sm text-gray-500 text-center max-w-sm">
        {{@description}}
      </p>
    {{/if}}
    {{#if @actionLabel}}
      <button
        type="button"
        class="mt-4 btn btn-primary"
        {{on "click" @onAction}}
      >
        {{@actionLabel}}
      </button>
    {{/if}}
  </div>
</template>;

const Badge = <template>
  <span class="badge inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
    {{if (eq @variant 'success') 'bg-green-100 text-green-800'
      (if (eq @variant 'warning') 'bg-yellow-100 text-yellow-800'
        (if (eq @variant 'danger') 'bg-red-100 text-red-800'
          (if (eq @variant 'info') 'bg-blue-100 text-blue-800'
            'bg-gray-100 text-gray-800')))}}">
    {{#if @dot}}
      <span class="badge-dot w-1.5 h-1.5 rounded-full mr-1.5
        {{if (eq @variant 'success') 'bg-green-400'
          (if (eq @variant 'warning') 'bg-yellow-400'
            (if (eq @variant 'danger') 'bg-red-400'
              (if (eq @variant 'info') 'bg-blue-400'
                'bg-gray-400')))}}">
      </span>
    {{/if}}
    {{yield}}
  </span>
</template>;

const Avatar = <template>
  <div class="avatar relative inline-flex items-center justify-center
    {{if (eq @size 'sm') 'w-8 h-8 text-xs'
      (if (eq @size 'lg') 'w-12 h-12 text-base'
        (if (eq @size 'xl') 'w-16 h-16 text-lg'
          'w-10 h-10 text-sm'))}}
    rounded-full overflow-hidden">
    {{#if @src}}
      <img src={{@src}} alt={{@alt}} class="w-full h-full object-cover" loading="lazy" />
    {{else}}
      <div class="w-full h-full flex items-center justify-center bg-indigo-100 text-indigo-600 font-medium">
        {{@initials}}
      </div>
    {{/if}}
    {{#if @online}}
      <span class="avatar-status absolute bottom-0 right-0 w-2.5 h-2.5 bg-green-400 border-2 border-white rounded-full"></span>
    {{/if}}
  </div>
</template>;

const Card = <template>
  <div class="card bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden
    {{if @hoverable 'hover:shadow-md transition-shadow cursor-pointer'}}
    {{if @selected 'ring-2 ring-indigo-500'}}
    {{@class}}">
    {{#if @header}}
      <div class="card-header px-6 py-4 border-b border-gray-200 flex items-center justify-between">
        <h3 class="card-title text-base font-semibold text-gray-900">{{@header}}</h3>
        {{#if (has-block "headerActions")}}
          <div class="card-header-actions flex items-center gap-2">
            {{yield to="headerActions"}}
          </div>
        {{/if}}
      </div>
    {{/if}}
    <div class="card-body {{if @noPadding '' 'p-6'}}">
      {{yield}}
    </div>
    {{#if (has-block "footer")}}
      <div class="card-footer px-6 py-3 bg-gray-50 border-t border-gray-200">
        {{yield to="footer"}}
      </div>
    {{/if}}
  </div>
</template>;

const ProgressBar = <template>
  <div class="progress-bar-container">
    {{#if @label}}
      <div class="flex items-center justify-between mb-1">
        <span class="text-sm font-medium text-gray-700">{{@label}}</span>
        <span class="text-sm text-gray-500">{{@value}}%</span>
      </div>
    {{/if}}
    <div class="progress-bar w-full bg-gray-200 rounded-full h-2.5 overflow-hidden" role="progressbar"
      aria-valuenow={{@value}} aria-valuemin="0" aria-valuemax="100">
      <div
        class="progress-bar-fill h-full rounded-full transition-all duration-300
          {{if (eq @color 'green') 'bg-green-500'
            (if (eq @color 'red') 'bg-red-500'
              (if (eq @color 'yellow') 'bg-yellow-500'
                'bg-indigo-500'))}}"
        style="width: {{@value}}%"
      ></div>
    </div>
  </div>
</template>;

const StatCard = <template>
  <div class="stat-card bg-white rounded-lg shadow-sm border border-gray-200 p-6">
    <div class="flex items-center justify-between">
      <div class="stat-content">
        <p class="stat-label text-sm font-medium text-gray-500 mb-1">{{@label}}</p>
        <p class="stat-value text-2xl font-bold text-gray-900">{{@value}}</p>
        {{#if @change}}
          <div class="stat-change flex items-center mt-1">
            {{#if @changePositive}}
              <svg class="w-4 h-4 text-green-500 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" />
              </svg>
              <span class="text-sm text-green-600">{{@change}}</span>
            {{else}}
              <svg class="w-4 h-4 text-red-500 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" />
              </svg>
              <span class="text-sm text-red-600">{{@change}}</span>
            {{/if}}
          </div>
        {{/if}}
      </div>
      {{#if @icon}}
        <div class="stat-icon flex-shrink-0 p-3 rounded-full bg-indigo-50">
          <span class="text-2xl">{{@icon}}</span>
        </div>
      {{/if}}
    </div>
  </div>
</template>;

const Breadcrumb = <template>
  <nav class="breadcrumb flex items-center space-x-2 text-sm" aria-label="Breadcrumb">
    {{#each @items as |item index|}}
      {{#if (eq index 0)}}
        {{!-- no separator --}}
      {{else}}
        <svg class="breadcrumb-separator w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" />
        </svg>
      {{/if}}
      {{#if item.active}}
        <span class="breadcrumb-current font-medium text-gray-900" aria-current="page">
          {{item.label}}
        </span>
      {{else}}
        <a href={{item.href}} class="breadcrumb-link text-gray-500 hover:text-gray-700">
          {{item.label}}
        </a>
      {{/if}}
    {{/each}}
  </nav>
</template>;

const TabBar = <template>
  <div class="tab-bar border-b border-gray-200">
    <nav class="tab-bar-nav flex space-x-8 -mb-px" role="tablist">
      {{#each @tabs as |tab|}}
        <button
          type="button"
          role="tab"
          class="tab-item whitespace-nowrap py-3 px-1 border-b-2 font-medium text-sm transition-colors
            {{if (eq tab.id @activeTab)
              'border-indigo-500 text-indigo-600'
              'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}}"
          aria-selected={{if (eq tab.id @activeTab) "true" "false"}}
          {{on "click" (fn @onTabChange tab.id)}}
        >
          {{tab.label}}
          {{#if tab.count}}
            <span class="tab-count ml-2 px-2 py-0.5 rounded-full text-xs
              {{if (eq tab.id @activeTab) 'bg-indigo-100 text-indigo-600' 'bg-gray-100 text-gray-600'}}">
              {{tab.count}}
            </span>
          {{/if}}
        </button>
      {{/each}}
    </nav>
  </div>
</template>;

const Pagination = <template>
  <nav class="pagination flex items-center justify-between px-4 py-3 bg-white border-t border-gray-200" aria-label="Pagination">
    <div class="pagination-info hidden sm:block">
      <p class="text-sm text-gray-700">
        Showing
        <span class="font-medium">{{@from}}</span>
        to
        <span class="font-medium">{{@to}}</span>
        of
        <span class="font-medium">{{@total}}</span>
        results
      </p>
    </div>
    <div class="pagination-controls flex items-center space-x-2">
      <button
        type="button"
        class="pagination-prev px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={{@isFirstPage}}
        {{on "click" @onPrevPage}}
      >
        Previous
      </button>
      {{#each @pageNumbers as |pageNum|}}
        <button
          type="button"
          class="pagination-page px-3 py-1.5 text-sm font-medium rounded-md
            {{if (eq pageNum @currentPage)
              'bg-indigo-600 text-white'
              'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50'}}"
          {{on "click" (fn @onGoToPage pageNum)}}
        >
          {{pageNum}}
        </button>
      {{/each}}
      <button
        type="button"
        class="pagination-next px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={{@isLastPage}}
        {{on "click" @onNextPage}}
      >
        Next
      </button>
    </div>
  </nav>
</template>;

const AlertBanner = <template>
  <div class="alert-banner rounded-md p-4 mb-4
    {{if (eq @type 'error') 'bg-red-50 border border-red-200'
      (if (eq @type 'warning') 'bg-yellow-50 border border-yellow-200'
        (if (eq @type 'success') 'bg-green-50 border border-green-200'
          'bg-blue-50 border border-blue-200'))}}"
    role="alert"
  >
    <div class="flex">
      <div class="alert-icon flex-shrink-0 mr-3">
        {{#if (eq @type 'error')}}
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" />
          </svg>
        {{else if (eq @type 'warning')}}
          <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" />
          </svg>
        {{else if (eq @type 'success')}}
          <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" />
          </svg>
        {{else}}
          <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" />
          </svg>
        {{/if}}
      </div>
      <div class="alert-content flex-1">
        {{#if @title}}
          <h3 class="alert-title text-sm font-medium
            {{if (eq @type 'error') 'text-red-800'
              (if (eq @type 'warning') 'text-yellow-800'
                (if (eq @type 'success') 'text-green-800'
                  'text-blue-800'))}}">
            {{@title}}
          </h3>
        {{/if}}
        <div class="alert-body text-sm mt-1
          {{if (eq @type 'error') 'text-red-700'
            (if (eq @type 'warning') 'text-yellow-700'
              (if (eq @type 'success') 'text-green-700'
                'text-blue-700'))}}">
          {{yield}}
        </div>
      </div>
      {{#if @dismissible}}
        <div class="alert-dismiss ml-3 flex-shrink-0">
          <button
            type="button"
            class="inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2
              {{if (eq @type 'error') 'text-red-500 hover:bg-red-100 focus:ring-red-600'
                (if (eq @type 'warning') 'text-yellow-500 hover:bg-yellow-100 focus:ring-yellow-600'
                  (if (eq @type 'success') 'text-green-500 hover:bg-green-100 focus:ring-green-600'
                    'text-blue-500 hover:bg-blue-100 focus:ring-blue-600'))}}"
            {{on "click" @onDismiss}}
          >
            <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" />
            </svg>
          </button>
        </div>
      {{/if}}
    </div>
  </div>
</template>;

const DropdownMenu = <template>
  <div class="dropdown-menu relative inline-block text-left">
    <div class="dropdown-trigger">
      {{yield to="trigger"}}
    </div>
    {{#if @isOpen}}
      <div class="dropdown-panel origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50"
        {{onClickOutside @onClose}}
        role="menu"
        aria-orientation="vertical"
      >
        <div class="dropdown-items py-1" role="none">
          {{#each @items as |item|}}
            {{#if item.divider}}
              <div class="dropdown-divider border-t border-gray-100 my-1"></div>
            {{else}}
              <button
                type="button"
                class="dropdown-item w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 hover:text-gray-900 flex items-center
                  {{if item.danger 'text-red-600 hover:text-red-700 hover:bg-red-50'}}"
                role="menuitem"
                disabled={{item.disabled}}
                {{on "click" (fn @onSelect item)}}
              >
                {{#if item.icon}}
                  <span class="dropdown-item-icon mr-3 text-gray-400">{{item.icon}}</span>
                {{/if}}
                <span class="dropdown-item-label">{{item.label}}</span>
                {{#if item.shortcut}}
                  <span class="dropdown-item-shortcut ml-auto text-xs text-gray-400">{{item.shortcut}}</span>
                {{/if}}
              </button>
            {{/if}}
          {{/each}}
        </div>
      </div>
    {{/if}}
  </div>
</template>;

const SearchInput = <template>
  <div class="search-input relative">
    <div class="search-icon absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
      <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" />
      </svg>
    </div>
    <input
      type="search"
      class="search-field block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
      placeholder={{if @placeholder @placeholder "Search..."}}
      value={{@value}}
      {{on "input" @onInput}}
      {{on "keydown" @onKeyDown}}
      {{autoFocus}}
    />
    {{#if @value}}
      <button
        type="button"
        class="search-clear absolute inset-y-0 right-0 pr-3 flex items-center"
        {{on "click" @onClear}}
      >
        <svg class="h-4 w-4 text-gray-400 hover:text-gray-600" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" />
        </svg>
      </button>
    {{/if}}
  </div>
</template>;

const Modal = <template>
  {{#if @isOpen}}
    <div class="modal-overlay fixed inset-0 z-50 overflow-y-auto">
      <div class="modal-backdrop fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        {{on "click" @onClose}}></div>
      <div class="modal-container flex min-h-full items-center justify-center p-4">
        <div class="modal-content relative bg-white rounded-lg shadow-xl w-full
          {{if (eq @size 'sm') 'max-w-sm'
            (if (eq @size 'lg') 'max-w-2xl'
              (if (eq @size 'xl') 'max-w-4xl'
                'max-w-lg'))}}"
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-title"
        >
          <div class="modal-header flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h3 id="modal-title" class="text-lg font-semibold text-gray-900">{{@title}}</h3>
            <button
              type="button"
              class="modal-close text-gray-400 hover:text-gray-500 focus:outline-none"
              {{on "click" @onClose}}
            >
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" />
              </svg>
            </button>
          </div>
          <div class="modal-body px-6 py-4">
            {{yield}}
          </div>
          {{#if (has-block "footer")}}
            <div class="modal-footer px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-end space-x-3 rounded-b-lg">
              {{yield to="footer"}}
            </div>
          {{/if}}
        </div>
      </div>
    </div>
  {{/if}}
</template>;

const Toggle = <template>
  <button
    type="button"
    class="toggle relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2
      {{if @checked 'bg-indigo-600' 'bg-gray-200'}}"
    role="switch"
    aria-checked={{if @checked "true" "false"}}
    aria-label={{@label}}
    {{on "click" @onChange}}
  >
    <span class="toggle-knob pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out
      {{if @checked 'translate-x-5' 'translate-x-0'}}">
    </span>
  </button>
</template>;

// ─── Class-Based Components ──────────────────────────────────────────────────

class DataTableManager extends Component {
  @tracked sortColumn = 'name';
  @tracked sortDirection = SORT_ASC;
  @tracked searchQuery = '';
  @tracked currentPage = 1;
  @tracked selectedRows = [];
  @tracked isFilterPanelOpen = false;
  @tracked filterStatus = null;
  @tracked filterPriority = null;
  @tracked filterDateFrom = null;
  @tracked filterDateTo = null;
  @tracked columnVisibility = {};
  @tracked isExporting = false;
  @tracked rowsPerPage = PAGE_SIZE;
  @tracked expandedRows = new Set();

  get filteredData() {
    let data = this.args.data || [];

    data = filterBySearch(data, this.searchQuery, ['name', 'email', 'description']);

    if (this.filterStatus) {
      data = data.filter((item) => item.status === this.filterStatus);
    }

    if (this.filterPriority) {
      data = data.filter((item) => item.priority === this.filterPriority);
    }

    if (this.filterDateFrom) {
      const from = new Date(this.filterDateFrom);
      data = data.filter((item) => new Date(item.createdAt) >= from);
    }

    if (this.filterDateTo) {
      const to = new Date(this.filterDateTo);
      data = data.filter((item) => new Date(item.createdAt) <= to);
    }

    return data;
  }

  get sortedData() {
    return sortBy(this.filteredData, this.sortColumn, this.sortDirection);
  }

  get paginatedData() {
    return paginate(this.sortedData, this.currentPage, this.rowsPerPage);
  }

  get totalPages() {
    return Math.ceil(this.filteredData.length / this.rowsPerPage);
  }

  get pageNumbers() {
    const pages = [];
    const start = Math.max(1, this.currentPage - 2);
    const end = Math.min(this.totalPages, start + 4);
    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    return pages;
  }

  get isFirstPage() {
    return this.currentPage <= 1;
  }

  get isLastPage() {
    return this.currentPage >= this.totalPages;
  }

  get fromRecord() {
    return (this.currentPage - 1) * this.rowsPerPage + 1;
  }

  get toRecord() {
    return Math.min(this.currentPage * this.rowsPerPage, this.filteredData.length);
  }

  get allSelected() {
    return this.paginatedData.length > 0 &&
      this.paginatedData.every((row) => this.selectedRows.includes(row.id));
  }

  get someSelected() {
    return this.selectedRows.length > 0 && !this.allSelected;
  }

  get hasActiveFilters() {
    return this.filterStatus || this.filterPriority || this.filterDateFrom || this.filterDateTo;
  }

  get activeFilterCount() {
    let count = 0;
    if (this.filterStatus) count++;
    if (this.filterPriority) count++;
    if (this.filterDateFrom) count++;
    if (this.filterDateTo) count++;
    return count;
  }

  get statusCounts() {
    const data = this.args.data || [];
    return {
      active: data.filter((d) => d.status === STATUS_ACTIVE).length,
      inactive: data.filter((d) => d.status === STATUS_INACTIVE).length,
      pending: data.filter((d) => d.status === STATUS_PENDING).length,
      archived: data.filter((d) => d.status === STATUS_ARCHIVED).length,
    };
  }

  get summaryStats() {
    const data = this.filteredData;
    return {
      total: data.length,
      totalRevenue: sumBy(data, 'revenue'),
      averageScore: averageBy(data, 'score'),
      completionRate: computePercentage(
        data.filter((d) => d.status === STATUS_ACTIVE).length,
        data.length
      ),
    };
  }

  @action
  handleSort(column) {
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === SORT_ASC ? SORT_DESC : SORT_ASC;
    } else {
      this.sortColumn = column;
      this.sortDirection = SORT_ASC;
    }
    this.currentPage = 1;
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
  goToPage(page) {
    this.currentPage = clamp(page, 1, this.totalPages);
  }

  @action
  nextPage() {
    this.goToPage(this.currentPage + 1);
  }

  @action
  prevPage() {
    this.goToPage(this.currentPage - 1);
  }

  @action
  toggleRowSelection(rowId) {
    const idx = this.selectedRows.indexOf(rowId);
    if (idx >= 0) {
      this.selectedRows = this.selectedRows.filter((id) => id !== rowId);
    } else {
      this.selectedRows = [...this.selectedRows, rowId];
    }
  }

  @action
  toggleSelectAll() {
    if (this.allSelected) {
      this.selectedRows = [];
    } else {
      this.selectedRows = this.paginatedData.map((row) => row.id);
    }
  }

  @action
  toggleFilterPanel() {
    this.isFilterPanelOpen = !this.isFilterPanelOpen;
  }

  @action
  setFilterStatus(event) {
    this.filterStatus = event.target.value || null;
    this.currentPage = 1;
  }

  @action
  setFilterPriority(event) {
    this.filterPriority = Number(event.target.value) || null;
    this.currentPage = 1;
  }

  @action
  setFilterDateFrom(event) {
    this.filterDateFrom = event.target.value || null;
    this.currentPage = 1;
  }

  @action
  setFilterDateTo(event) {
    this.filterDateTo = event.target.value || null;
    this.currentPage = 1;
  }

  @action
  clearAllFilters() {
    this.filterStatus = null;
    this.filterPriority = null;
    this.filterDateFrom = null;
    this.filterDateTo = null;
    this.searchQuery = '';
    this.currentPage = 1;
  }

  @action
  toggleRowExpansion(rowId) {
    const expanded = new Set(this.expandedRows);
    if (expanded.has(rowId)) {
      expanded.delete(rowId);
    } else {
      expanded.add(rowId);
    }
    this.expandedRows = expanded;
  }

  @action
  handleRowsPerPageChange(event) {
    this.rowsPerPage = Number(event.target.value);
    this.currentPage = 1;
  }

  @action
  async exportData() {
    this.isExporting = true;
    try {
      const data = this.sortedData;
      const csv = data.map((row) =>
        Object.values(row).join(',')
      ).join('\n');
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'export.csv';
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      this.isExporting = false;
    }
  }

  @action
  handleBulkAction(actionType) {
    if (this.args.onBulkAction) {
      this.args.onBulkAction(actionType, this.selectedRows);
    }
    this.selectedRows = [];
  }

  <template>
    <div class="data-table-manager">
      {{! Summary stats row }}
      <div class="stats-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          @label="Total Records"
          @value={{this.summaryStats.total}}
          @icon="*"
          @change="+12%"
          @changePositive={{true}}
        />
        <StatCard
          @label="Total Revenue"
          @value={{formatCurrency this.summaryStats.totalRevenue}}
          @icon="$"
          @change="+8.2%"
          @changePositive={{true}}
        />
        <StatCard
          @label="Avg Score"
          @value={{this.summaryStats.averageScore}}
          @icon="#"
          @change="-2.1%"
          @changePositive={{false}}
        />
        <StatCard
          @label="Completion Rate"
          @value="{{this.summaryStats.completionRate}}%"
          @icon="!"
          @change="+5.4%"
          @changePositive={{true}}
        />
      </div>

      {{! Toolbar }}
      <div class="table-toolbar flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-4">
        <div class="toolbar-left flex items-center gap-3 w-full sm:w-auto">
          <SearchInput
            @value={{this.searchQuery}}
            @onInput={{this.handleSearch}}
            @onClear={{this.clearSearch}}
            @placeholder="Search records..."
          />
          <button
            type="button"
            class="filter-toggle inline-flex items-center px-3 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
            {{on "click" this.toggleFilterPanel}}
          >
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
            </svg>
            Filters
            {{#if this.hasActiveFilters}}
              <Badge @variant="info">{{this.activeFilterCount}}</Badge>
            {{/if}}
          </button>
        </div>

        <div class="toolbar-right flex items-center gap-2">
          {{#if this.selectedRows.length}}
            <span class="text-sm text-gray-500 mr-2">{{this.selectedRows.length}} selected</span>
            <button
              type="button"
              class="btn btn-sm btn-outline"
              {{on "click" (fn this.handleBulkAction "archive")}}
            >Archive</button>
            <button
              type="button"
              class="btn btn-sm btn-danger"
              {{on "click" (fn this.handleBulkAction "delete")}}
            >Delete</button>
          {{/if}}
          <button
            type="button"
            class="btn btn-sm btn-outline"
            disabled={{this.isExporting}}
            {{on "click" this.exportData}}
          >
            {{#if this.isExporting}}
              <LoadingSpinner @size="sm" />
            {{else}}
              Export CSV
            {{/if}}
          </button>
          <select
            class="rows-per-page border border-gray-300 rounded-md text-sm py-1.5 px-2"
            {{on "change" this.handleRowsPerPageChange}}
          >
            <option value="10">10 / page</option>
            <option value="25" selected>25 / page</option>
            <option value="50">50 / page</option>
            <option value="100">100 / page</option>
          </select>
        </div>
      </div>

      {{! Filter Panel }}
      {{#if this.isFilterPanelOpen}}
        <div class="filter-panel bg-gray-50 border border-gray-200 rounded-lg p-4 mb-4">
          <div class="filter-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div class="filter-group">
              <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
              <select class="w-full border border-gray-300 rounded-md text-sm py-2 px-3" {{on "change" this.setFilterStatus}}>
                <option value="">All statuses</option>
                <option value="active">Active ({{this.statusCounts.active}})</option>
                <option value="inactive">Inactive ({{this.statusCounts.inactive}})</option>
                <option value="pending">Pending ({{this.statusCounts.pending}})</option>
                <option value="archived">Archived ({{this.statusCounts.archived}})</option>
              </select>
            </div>
            <div class="filter-group">
              <label class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
              <select class="w-full border border-gray-300 rounded-md text-sm py-2 px-3" {{on "change" this.setFilterPriority}}>
                <option value="">All priorities</option>
                <option value="1">Low</option>
                <option value="2">Medium</option>
                <option value="3">High</option>
                <option value="4">Critical</option>
              </select>
            </div>
            <div class="filter-group">
              <label class="block text-sm font-medium text-gray-700 mb-1">From Date</label>
              <input type="date" class="w-full border border-gray-300 rounded-md text-sm py-2 px-3"
                {{on "change" this.setFilterDateFrom}} />
            </div>
            <div class="filter-group">
              <label class="block text-sm font-medium text-gray-700 mb-1">To Date</label>
              <input type="date" class="w-full border border-gray-300 rounded-md text-sm py-2 px-3"
                {{on "change" this.setFilterDateTo}} />
            </div>
          </div>
          {{#if this.hasActiveFilters}}
            <div class="filter-actions mt-3 flex justify-end">
              <button
                type="button"
                class="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
                {{on "click" this.clearAllFilters}}
              >
                Clear all filters
              </button>
            </div>
          {{/if}}
        </div>
      {{/if}}

      {{! Data Table }}
      <div class="table-container overflow-x-auto border border-gray-200 rounded-lg">
        <table class="data-table min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-3 w-10">
                <input
                  type="checkbox"
                  class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  checked={{this.allSelected}}
                  {{on "change" this.toggleSelectAll}}
                />
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "name")}}>
                <div class="flex items-center gap-1">
                  Name
                  {{#if (eq this.sortColumn "name")}}
                    <span class="sort-indicator">{{if (eq this.sortDirection "asc") "^" "v"}}</span>
                  {{/if}}
                </div>
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "email")}}>
                <div class="flex items-center gap-1">
                  Email
                  {{#if (eq this.sortColumn "email")}}
                    <span class="sort-indicator">{{if (eq this.sortDirection "asc") "^" "v"}}</span>
                  {{/if}}
                </div>
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "status")}}>
                Status
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "priority")}}>
                Priority
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "revenue")}}>
                Revenue
              </th>
              <th class="table-header px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700 select-none"
                {{on "click" (fn this.handleSort "createdAt")}}>
                Created
              </th>
              <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            {{#each this.paginatedData as |row|}}
              <tr class="table-row hover:bg-gray-50 transition-colors
                {{if (fn this.selectedRows.includes row.id) 'bg-indigo-50'}}">
                <td class="px-3 py-4">
                  <input
                    type="checkbox"
                    class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                    checked={{fn this.selectedRows.includes row.id}}
                    {{on "change" (fn this.toggleRowSelection row.id)}}
                  />
                </td>
                <td class="table-cell px-4 py-4">
                  <div class="flex items-center">
                    <Avatar @initials={{getInitials row.name}} @size="sm" @online={{eq row.status "active"}} />
                    <div class="ml-3">
                      <div class="text-sm font-medium text-gray-900">{{row.name}}</div>
                      <div class="text-xs text-gray-500">{{row.role}}</div>
                    </div>
                  </div>
                </td>
                <td class="table-cell px-4 py-4 text-sm text-gray-600">
                  {{row.email}}
                </td>
                <td class="table-cell px-4 py-4">
                  <Badge @variant={{getStatusColor row.status}} @dot={{true}}>
                    {{capitalize row.status}}
                  </Badge>
                </td>
                <td class="table-cell px-4 py-4">
                  <span class="text-sm font-medium {{getPriorityColor row.priority}}">
                    {{getPriorityLabel row.priority}}
                  </span>
                </td>
                <td class="table-cell px-4 py-4 text-sm text-gray-900 font-mono">
                  {{formatCurrency row.revenue}}
                </td>
                <td class="table-cell px-4 py-4 text-sm text-gray-500">
                  {{formatRelativeTime row.createdAt}}
                </td>
                <td class="table-cell px-4 py-4 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <button
                      type="button"
                      class="text-gray-400 hover:text-gray-600"
                      {{tooltip "View details"}}
                      {{on "click" (fn this.toggleRowExpansion row.id)}}
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    </button>
                    <button
                      type="button"
                      class="text-gray-400 hover:text-indigo-600"
                      {{tooltip "Edit"}}
                      {{on "click" (fn @onEdit row)}}
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button
                      type="button"
                      class="text-gray-400 hover:text-red-600"
                      {{tooltip "Delete"}}
                      {{on "click" (fn @onDelete row)}}
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </td>
              </tr>
              {{!-- Expanded row detail --}}
              {{#if (fn this.expandedRows.has row.id)}}
                <tr class="expanded-row bg-gray-50">
                  <td colspan="8" class="px-8 py-4">
                    <div class="expanded-content grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div class="detail-section">
                        <h4 class="text-sm font-semibold text-gray-700 mb-2">Contact Info</h4>
                        <dl class="space-y-1">
                          <div class="flex justify-between">
                            <dt class="text-xs text-gray-500">Phone</dt>
                            <dd class="text-xs text-gray-900">{{row.phone}}</dd>
                          </div>
                          <div class="flex justify-between">
                            <dt class="text-xs text-gray-500">Location</dt>
                            <dd class="text-xs text-gray-900">{{row.location}}</dd>
                          </div>
                          <div class="flex justify-between">
                            <dt class="text-xs text-gray-500">Department</dt>
                            <dd class="text-xs text-gray-900">{{row.department}}</dd>
                          </div>
                        </dl>
                      </div>
                      <div class="detail-section">
                        <h4 class="text-sm font-semibold text-gray-700 mb-2">Performance</h4>
                        <div class="space-y-2">
                          <ProgressBar @label="Completion" @value={{row.completionRate}} @color="green" />
                          <ProgressBar @label="Quality Score" @value={{row.qualityScore}} @color="indigo" />
                          <ProgressBar @label="Response Time" @value={{row.responseRate}} @color="yellow" />
                        </div>
                      </div>
                      <div class="detail-section">
                        <h4 class="text-sm font-semibold text-gray-700 mb-2">Description</h4>
                        <p class="text-xs text-gray-600 leading-relaxed">{{row.description}}</p>
                      </div>
                    </div>
                  </td>
                </tr>
              {{/if}}
            {{else}}
              <tr>
                <td colspan="8">
                  <EmptyState
                    @title="No records found"
                    @description="Try adjusting your search or filter criteria to find what you're looking for."
                    @actionLabel="Clear filters"
                    @onAction={{this.clearAllFilters}}
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>

      {{! Pagination }}
      <Pagination
        @from={{this.fromRecord}}
        @to={{this.toRecord}}
        @total={{this.filteredData.length}}
        @currentPage={{this.currentPage}}
        @pageNumbers={{this.pageNumbers}}
        @isFirstPage={{this.isFirstPage}}
        @isLastPage={{this.isLastPage}}
        @onPrevPage={{this.prevPage}}
        @onNextPage={{this.nextPage}}
        @onGoToPage={{this.goToPage}}
      />
    </div>
  </template>
}

class SettingsPanel extends Component {
  @tracked activeSection = 'profile';
  @tracked profileName = '';
  @tracked profileEmail = '';
  @tracked profileBio = '';
  @tracked profileAvatar = null;
  @tracked profileTimezone = 'UTC';
  @tracked profileLanguage = 'en';

  @tracked notificationsEmail = true;
  @tracked notificationsPush = true;
  @tracked notificationsSlack = false;
  @tracked notificationsDigest = 'daily';
  @tracked notificationsMentions = true;
  @tracked notificationsUpdates = true;
  @tracked notificationsMarketing = false;

  @tracked securityTwoFactor = false;
  @tracked securitySessionTimeout = 30;
  @tracked securityLoginAlerts = true;
  @tracked securityApiKeys = [];
  @tracked securityPasswordLastChanged = null;

  @tracked appearanceTheme = THEME_AUTO;
  @tracked appearanceDensity = 'comfortable';
  @tracked appearanceFontSize = 'medium';
  @tracked appearanceSidebarCollapsed = false;
  @tracked appearanceAnimations = true;
  @tracked appearanceHighContrast = false;

  @tracked integrationGithub = false;
  @tracked integrationSlack = false;
  @tracked integrationJira = false;
  @tracked integrationGoogleDrive = false;
  @tracked integrationFigma = false;

  @tracked isSaving = false;
  @tracked saveSuccess = false;
  @tracked saveError = null;
  @tracked isDirty = false;
  @tracked showDeleteConfirm = false;
  @tracked deleteConfirmText = '';

  get settingsSections() {
    return [
      { id: 'profile', label: 'Profile', icon: 'U' },
      { id: 'notifications', label: 'Notifications', icon: 'B' },
      { id: 'security', label: 'Security', icon: 'S' },
      { id: 'appearance', label: 'Appearance', icon: 'A' },
      { id: 'integrations', label: 'Integrations', icon: 'I' },
      { id: 'billing', label: 'Billing', icon: '$' },
      { id: 'danger', label: 'Danger Zone', icon: '!' },
    ];
  }

  get canDelete() {
    return this.deleteConfirmText === 'DELETE';
  }

  get themeOptions() {
    return [
      { value: THEME_LIGHT, label: 'Light' },
      { value: THEME_DARK, label: 'Dark' },
      { value: THEME_AUTO, label: 'System' },
    ];
  }

  get densityOptions() {
    return [
      { value: 'compact', label: 'Compact' },
      { value: 'comfortable', label: 'Comfortable' },
      { value: 'spacious', label: 'Spacious' },
    ];
  }

  get fontSizeOptions() {
    return [
      { value: 'small', label: 'Small' },
      { value: 'medium', label: 'Medium' },
      { value: 'large', label: 'Large' },
    ];
  }

  get digestOptions() {
    return [
      { value: 'realtime', label: 'Real-time' },
      { value: 'hourly', label: 'Hourly' },
      { value: 'daily', label: 'Daily digest' },
      { value: 'weekly', label: 'Weekly digest' },
      { value: 'never', label: 'Never' },
    ];
  }

  @action
  setActiveSection(sectionId) {
    this.activeSection = sectionId;
  }

  @action
  updateProfileName(event) {
    this.profileName = event.target.value;
    this.isDirty = true;
  }

  @action
  updateProfileEmail(event) {
    this.profileEmail = event.target.value;
    this.isDirty = true;
  }

  @action
  updateProfileBio(event) {
    this.profileBio = event.target.value;
    this.isDirty = true;
  }

  @action
  updateProfileTimezone(event) {
    this.profileTimezone = event.target.value;
    this.isDirty = true;
  }

  @action
  updateProfileLanguage(event) {
    this.profileLanguage = event.target.value;
    this.isDirty = true;
  }

  @action
  toggleNotificationsEmail() {
    this.notificationsEmail = !this.notificationsEmail;
    this.isDirty = true;
  }

  @action
  toggleNotificationsPush() {
    this.notificationsPush = !this.notificationsPush;
    this.isDirty = true;
  }

  @action
  toggleNotificationsSlack() {
    this.notificationsSlack = !this.notificationsSlack;
    this.isDirty = true;
  }

  @action
  updateNotificationsDigest(event) {
    this.notificationsDigest = event.target.value;
    this.isDirty = true;
  }

  @action
  toggleNotificationsMentions() {
    this.notificationsMentions = !this.notificationsMentions;
    this.isDirty = true;
  }

  @action
  toggleNotificationsUpdates() {
    this.notificationsUpdates = !this.notificationsUpdates;
    this.isDirty = true;
  }

  @action
  toggleNotificationsMarketing() {
    this.notificationsMarketing = !this.notificationsMarketing;
    this.isDirty = true;
  }

  @action
  toggleSecurityTwoFactor() {
    this.securityTwoFactor = !this.securityTwoFactor;
    this.isDirty = true;
  }

  @action
  updateSessionTimeout(event) {
    this.securitySessionTimeout = Number(event.target.value);
    this.isDirty = true;
  }

  @action
  toggleSecurityLoginAlerts() {
    this.securityLoginAlerts = !this.securityLoginAlerts;
    this.isDirty = true;
  }

  @action
  setAppearanceTheme(theme) {
    this.appearanceTheme = theme;
    this.isDirty = true;
  }

  @action
  updateAppearanceDensity(event) {
    this.appearanceDensity = event.target.value;
    this.isDirty = true;
  }

  @action
  updateAppearanceFontSize(event) {
    this.appearanceFontSize = event.target.value;
    this.isDirty = true;
  }

  @action
  toggleSidebarCollapsed() {
    this.appearanceSidebarCollapsed = !this.appearanceSidebarCollapsed;
    this.isDirty = true;
  }

  @action
  toggleAnimations() {
    this.appearanceAnimations = !this.appearanceAnimations;
    this.isDirty = true;
  }

  @action
  toggleHighContrast() {
    this.appearanceHighContrast = !this.appearanceHighContrast;
    this.isDirty = true;
  }

  @action
  toggleIntegration(name) {
    const key = `integration${capitalize(name)}`;
    this[key] = !this[key];
    this.isDirty = true;
  }

  @action
  updateDeleteConfirmText(event) {
    this.deleteConfirmText = event.target.value;
  }

  @action
  toggleDeleteConfirm() {
    this.showDeleteConfirm = !this.showDeleteConfirm;
    this.deleteConfirmText = '';
  }

  @action
  async saveSettings() {
    this.isSaving = true;
    this.saveError = null;
    this.saveSuccess = false;
    try {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      this.saveSuccess = true;
      this.isDirty = false;
      setTimeout(() => {
        this.saveSuccess = false;
      }, 3000);
    } catch (err) {
      this.saveError = err.message || 'Failed to save settings';
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async deleteAccount() {
    if (!this.canDelete) return;
    if (this.args.onDeleteAccount) {
      await this.args.onDeleteAccount();
    }
  }

  <template>
    <div class="settings-panel flex h-full">
      {{! Sidebar nav }}
      <nav class="settings-nav w-56 border-r border-gray-200 bg-gray-50 py-4">
        <ul class="space-y-1 px-2">
          {{#each this.settingsSections as |section|}}
            <li>
              <button
                type="button"
                class="settings-nav-item w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors
                  {{if (eq section.id this.activeSection)
                    'bg-indigo-50 text-indigo-700'
                    'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}}"
                {{on "click" (fn this.setActiveSection section.id)}}
              >
                <span class="nav-icon mr-3 text-lg">{{section.icon}}</span>
                {{section.label}}
              </button>
            </li>
          {{/each}}
        </ul>
      </nav>

      {{! Settings content }}
      <div class="settings-content flex-1 overflow-y-auto p-8">
        {{#if this.saveSuccess}}
          <AlertBanner @type="success" @dismissible={{true}} @onDismiss={{fn (mut this.saveSuccess) false}}>
            Settings saved successfully.
          </AlertBanner>
        {{/if}}

        {{#if this.saveError}}
          <AlertBanner @type="error" @dismissible={{true}} @onDismiss={{fn (mut this.saveError) null}}>
            {{this.saveError}}
          </AlertBanner>
        {{/if}}

        {{! Profile Section }}
        {{#if (eq this.activeSection "profile")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-gray-900 mb-1">Profile Settings</h2>
            <p class="text-sm text-gray-500 mb-6">Manage your personal information and preferences.</p>

            <div class="settings-form space-y-6">
              <div class="form-group">
                <label class="block text-sm font-medium text-gray-700 mb-1">Avatar</label>
                <div class="flex items-center gap-4">
                  <Avatar @initials={{getInitials this.profileName}} @size="xl" />
                  <div>
                    <button type="button" class="btn btn-sm btn-outline">Change avatar</button>
                    <p class="text-xs text-gray-500 mt-1">JPG, GIF or PNG. 1MB max.</p>
                  </div>
                </div>
              </div>

              <div class="form-row grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="form-group">
                  <label for="profile-name" class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                  <input
                    id="profile-name"
                    type="text"
                    class="form-input w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500"
                    value={{this.profileName}}
                    placeholder="Enter your full name"
                    {{on "input" this.updateProfileName}}
                  />
                </div>
                <div class="form-group">
                  <label for="profile-email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                  <input
                    id="profile-email"
                    type="email"
                    class="form-input w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500"
                    value={{this.profileEmail}}
                    placeholder="you@example.com"
                    {{on "input" this.updateProfileEmail}}
                  />
                </div>
              </div>

              <div class="form-group">
                <label for="profile-bio" class="block text-sm font-medium text-gray-700 mb-1">Bio</label>
                <textarea
                  id="profile-bio"
                  rows="4"
                  class="form-textarea w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="Tell us about yourself..."
                  {{on "input" this.updateProfileBio}}
                >{{this.profileBio}}</textarea>
                <p class="text-xs text-gray-400 mt-1">Brief description for your profile. Max 256 characters.</p>
              </div>

              <div class="form-row grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="form-group">
                  <label for="profile-timezone" class="block text-sm font-medium text-gray-700 mb-1">Timezone</label>
                  <select
                    id="profile-timezone"
                    class="form-select w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                    {{on "change" this.updateProfileTimezone}}
                  >
                    <option value="UTC">UTC</option>
                    <option value="US/Eastern">US/Eastern</option>
                    <option value="US/Central">US/Central</option>
                    <option value="US/Mountain">US/Mountain</option>
                    <option value="US/Pacific">US/Pacific</option>
                    <option value="Europe/London">Europe/London</option>
                    <option value="Europe/Berlin">Europe/Berlin</option>
                    <option value="Asia/Tokyo">Asia/Tokyo</option>
                    <option value="Australia/Sydney">Australia/Sydney</option>
                  </select>
                </div>
                <div class="form-group">
                  <label for="profile-language" class="block text-sm font-medium text-gray-700 mb-1">Language</label>
                  <select
                    id="profile-language"
                    class="form-select w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                    {{on "change" this.updateProfileLanguage}}
                  >
                    <option value="en">English</option>
                    <option value="es">Spanish</option>
                    <option value="fr">French</option>
                    <option value="de">German</option>
                    <option value="ja">Japanese</option>
                    <option value="zh">Chinese</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        {{/if}}

        {{! Notifications Section }}
        {{#if (eq this.activeSection "notifications")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-gray-900 mb-1">Notification Preferences</h2>
            <p class="text-sm text-gray-500 mb-6">Choose how and when you want to be notified.</p>

            <div class="notification-channels space-y-6">
              <Card @header="Delivery Channels">
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Email notifications</p>
                      <p class="text-xs text-gray-500">Receive notifications via email</p>
                    </div>
                    <Toggle @checked={{this.notificationsEmail}} @onChange={{this.toggleNotificationsEmail}} @label="Email notifications" />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Push notifications</p>
                      <p class="text-xs text-gray-500">Receive browser push notifications</p>
                    </div>
                    <Toggle @checked={{this.notificationsPush}} @onChange={{this.toggleNotificationsPush}} @label="Push notifications" />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Slack notifications</p>
                      <p class="text-xs text-gray-500">Send notifications to Slack</p>
                    </div>
                    <Toggle @checked={{this.notificationsSlack}} @onChange={{this.toggleNotificationsSlack}} @label="Slack notifications" />
                  </div>
                </div>
              </Card>

              <Card @header="Digest Frequency">
                <div class="space-y-3">
                  <label for="digest-freq" class="block text-sm font-medium text-gray-700">Email digest frequency</label>
                  <select
                    id="digest-freq"
                    class="form-select w-full sm:w-64 border border-gray-300 rounded-md px-3 py-2 text-sm"
                    {{on "change" this.updateNotificationsDigest}}
                  >
                    {{#each this.digestOptions as |opt|}}
                      <option value={{opt.value}} selected={{eq opt.value this.notificationsDigest}}>{{opt.label}}</option>
                    {{/each}}
                  </select>
                </div>
              </Card>

              <Card @header="Notification Types">
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Mentions</p>
                      <p class="text-xs text-gray-500">When someone mentions you in a comment</p>
                    </div>
                    <Toggle @checked={{this.notificationsMentions}} @onChange={{this.toggleNotificationsMentions}} @label="Mentions" />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Updates</p>
                      <p class="text-xs text-gray-500">When items you follow are updated</p>
                    </div>
                    <Toggle @checked={{this.notificationsUpdates}} @onChange={{this.toggleNotificationsUpdates}} @label="Updates" />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Marketing</p>
                      <p class="text-xs text-gray-500">Product news and announcements</p>
                    </div>
                    <Toggle @checked={{this.notificationsMarketing}} @onChange={{this.toggleNotificationsMarketing}} @label="Marketing" />
                  </div>
                </div>
              </Card>
            </div>
          </div>
        {{/if}}

        {{! Security Section }}
        {{#if (eq this.activeSection "security")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-gray-900 mb-1">Security Settings</h2>
            <p class="text-sm text-gray-500 mb-6">Manage your account security and authentication.</p>

            <div class="security-settings space-y-6">
              <Card @header="Two-Factor Authentication">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      {{#if this.securityTwoFactor}}
                        Two-factor authentication is enabled. Your account is more secure.
                      {{else}}
                        Add an extra layer of security to your account.
                      {{/if}}
                    </p>
                  </div>
                  <Toggle @checked={{this.securityTwoFactor}} @onChange={{this.toggleSecurityTwoFactor}} @label="Two-factor authentication" />
                </div>
              </Card>

              <Card @header="Session Management">
                <div class="space-y-4">
                  <div>
                    <label for="session-timeout" class="block text-sm font-medium text-gray-700 mb-1">Session timeout (minutes)</label>
                    <input
                      id="session-timeout"
                      type="number"
                      min="5"
                      max="1440"
                      class="form-input w-32 border border-gray-300 rounded-md px-3 py-2 text-sm"
                      value={{this.securitySessionTimeout}}
                      {{on "input" this.updateSessionTimeout}}
                    />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Login alerts</p>
                      <p class="text-xs text-gray-500">Get notified when someone logs into your account</p>
                    </div>
                    <Toggle @checked={{this.securityLoginAlerts}} @onChange={{this.toggleSecurityLoginAlerts}} @label="Login alerts" />
                  </div>
                </div>
              </Card>

              <Card @header="Password">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm text-gray-700">Last changed: {{if this.securityPasswordLastChanged (formatRelativeTime this.securityPasswordLastChanged) "Never"}}</p>
                  </div>
                  <button type="button" class="btn btn-sm btn-outline">Change password</button>
                </div>
              </Card>

              <Card @header="API Keys">
                <div class="space-y-3">
                  {{#each this.securityApiKeys as |key|}}
                    <div class="api-key-item flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                      <div>
                        <p class="text-sm font-medium text-gray-900">{{key.name}}</p>
                        <p class="text-xs text-gray-500">Created {{formatRelativeTime key.createdAt}} - Last used {{formatRelativeTime key.lastUsedAt}}</p>
                      </div>
                      <button type="button" class="text-sm text-red-600 hover:text-red-800">Revoke</button>
                    </div>
                  {{else}}
                    <p class="text-sm text-gray-500">No API keys configured.</p>
                  {{/each}}
                  <button type="button" class="btn btn-sm btn-outline mt-2">Generate new key</button>
                </div>
              </Card>
            </div>
          </div>
        {{/if}}

        {{! Appearance Section }}
        {{#if (eq this.activeSection "appearance")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-gray-900 mb-1">Appearance</h2>
            <p class="text-sm text-gray-500 mb-6">Customize how the application looks and feels.</p>

            <div class="appearance-settings space-y-6">
              <Card @header="Theme">
                <div class="theme-options grid grid-cols-3 gap-3">
                  {{#each this.themeOptions as |opt|}}
                    <button
                      type="button"
                      class="theme-option p-4 border-2 rounded-lg text-center transition-colors
                        {{if (eq opt.value this.appearanceTheme)
                          'border-indigo-500 bg-indigo-50'
                          'border-gray-200 hover:border-gray-300'}}"
                      {{on "click" (fn this.setAppearanceTheme opt.value)}}
                    >
                      <div class="theme-preview w-full h-16 rounded mb-2
                        {{if (eq opt.value 'light') 'bg-white border border-gray-200'
                          (if (eq opt.value 'dark') 'bg-gray-800'
                            'bg-gradient-to-r from-white to-gray-800')}}">
                      </div>
                      <span class="text-sm font-medium">{{opt.label}}</span>
                    </button>
                  {{/each}}
                </div>
              </Card>

              <Card @header="Layout">
                <div class="space-y-4">
                  <div class="form-group">
                    <label for="density" class="block text-sm font-medium text-gray-700 mb-1">Density</label>
                    <select
                      id="density"
                      class="form-select w-full sm:w-48 border border-gray-300 rounded-md px-3 py-2 text-sm"
                      {{on "change" this.updateAppearanceDensity}}
                    >
                      {{#each this.densityOptions as |opt|}}
                        <option value={{opt.value}} selected={{eq opt.value this.appearanceDensity}}>{{opt.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="form-group">
                    <label for="font-size" class="block text-sm font-medium text-gray-700 mb-1">Font size</label>
                    <select
                      id="font-size"
                      class="form-select w-full sm:w-48 border border-gray-300 rounded-md px-3 py-2 text-sm"
                      {{on "change" this.updateAppearanceFontSize}}
                    >
                      {{#each this.fontSizeOptions as |opt|}}
                        <option value={{opt.value}} selected={{eq opt.value this.appearanceFontSize}}>{{opt.label}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Collapsed sidebar</p>
                      <p class="text-xs text-gray-500">Show only icons in the sidebar</p>
                    </div>
                    <Toggle @checked={{this.appearanceSidebarCollapsed}} @onChange={{this.toggleSidebarCollapsed}} @label="Collapsed sidebar" />
                  </div>
                </div>
              </Card>

              <Card @header="Accessibility">
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">Animations</p>
                      <p class="text-xs text-gray-500">Enable transitions and animations</p>
                    </div>
                    <Toggle @checked={{this.appearanceAnimations}} @onChange={{this.toggleAnimations}} @label="Animations" />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">High contrast</p>
                      <p class="text-xs text-gray-500">Increase contrast for better readability</p>
                    </div>
                    <Toggle @checked={{this.appearanceHighContrast}} @onChange={{this.toggleHighContrast}} @label="High contrast" />
                  </div>
                </div>
              </Card>
            </div>
          </div>
        {{/if}}

        {{! Integrations Section }}
        {{#if (eq this.activeSection "integrations")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-gray-900 mb-1">Integrations</h2>
            <p class="text-sm text-gray-500 mb-6">Connect with third-party services and tools.</p>

            <div class="integrations-grid space-y-4">
              <Card>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="integration-icon w-10 h-10 rounded-lg bg-gray-900 flex items-center justify-center text-white font-bold">
                      GH
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">GitHub</p>
                      <p class="text-xs text-gray-500">Link pull requests and issues</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    {{#if this.integrationGithub}}
                      <Badge @variant="success">Connected</Badge>
                    {{/if}}
                    <button
                      type="button"
                      class="btn btn-sm {{if this.integrationGithub 'btn-outline' 'btn-primary'}}"
                      {{on "click" (fn this.toggleIntegration "github")}}
                    >
                      {{if this.integrationGithub "Disconnect" "Connect"}}
                    </button>
                  </div>
                </div>
              </Card>

              <Card>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="integration-icon w-10 h-10 rounded-lg bg-purple-600 flex items-center justify-center text-white font-bold">
                      SL
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">Slack</p>
                      <p class="text-xs text-gray-500">Send notifications to Slack channels</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    {{#if this.integrationSlack}}
                      <Badge @variant="success">Connected</Badge>
                    {{/if}}
                    <button
                      type="button"
                      class="btn btn-sm {{if this.integrationSlack 'btn-outline' 'btn-primary'}}"
                      {{on "click" (fn this.toggleIntegration "slack")}}
                    >
                      {{if this.integrationSlack "Disconnect" "Connect"}}
                    </button>
                  </div>
                </div>
              </Card>

              <Card>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="integration-icon w-10 h-10 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold">
                      JR
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">Jira</p>
                      <p class="text-xs text-gray-500">Sync tasks and track progress</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    {{#if this.integrationJira}}
                      <Badge @variant="success">Connected</Badge>
                    {{/if}}
                    <button
                      type="button"
                      class="btn btn-sm {{if this.integrationJira 'btn-outline' 'btn-primary'}}"
                      {{on "click" (fn this.toggleIntegration "jira")}}
                    >
                      {{if this.integrationJira "Disconnect" "Connect"}}
                    </button>
                  </div>
                </div>
              </Card>

              <Card>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="integration-icon w-10 h-10 rounded-lg bg-green-500 flex items-center justify-center text-white font-bold">
                      GD
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">Google Drive</p>
                      <p class="text-xs text-gray-500">Attach and preview documents</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    {{#if this.integrationGoogleDrive}}
                      <Badge @variant="success">Connected</Badge>
                    {{/if}}
                    <button
                      type="button"
                      class="btn btn-sm {{if this.integrationGoogleDrive 'btn-outline' 'btn-primary'}}"
                      {{on "click" (fn this.toggleIntegration "googleDrive")}}
                    >
                      {{if this.integrationGoogleDrive "Disconnect" "Connect"}}
                    </button>
                  </div>
                </div>
              </Card>

              <Card>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="integration-icon w-10 h-10 rounded-lg bg-pink-500 flex items-center justify-center text-white font-bold">
                      FG
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">Figma</p>
                      <p class="text-xs text-gray-500">Preview and embed design files</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    {{#if this.integrationFigma}}
                      <Badge @variant="success">Connected</Badge>
                    {{/if}}
                    <button
                      type="button"
                      class="btn btn-sm {{if this.integrationFigma 'btn-outline' 'btn-primary'}}"
                      {{on "click" (fn this.toggleIntegration "figma")}}
                    >
                      {{if this.integrationFigma "Disconnect" "Connect"}}
                    </button>
                  </div>
                </div>
              </Card>
            </div>
          </div>
        {{/if}}

        {{! Danger Zone Section }}
        {{#if (eq this.activeSection "danger")}}
          <div class="settings-section max-w-2xl">
            <h2 class="text-xl font-semibold text-red-600 mb-1">Danger Zone</h2>
            <p class="text-sm text-gray-500 mb-6">Irreversible and destructive actions.</p>

            <div class="danger-zone space-y-4">
              <div class="border-2 border-red-200 rounded-lg p-6">
                <h3 class="text-base font-semibold text-gray-900 mb-2">Delete Account</h3>
                <p class="text-sm text-gray-600 mb-4">
                  Once you delete your account, there is no going back. All your data will be permanently removed.
                  This action cannot be undone.
                </p>
                {{#if this.showDeleteConfirm}}
                  <div class="delete-confirm space-y-3">
                    <AlertBanner @type="error">
                      This will permanently delete your account and all associated data.
                    </AlertBanner>
                    <div class="form-group">
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Type <strong>DELETE</strong> to confirm
                      </label>
                      <input
                        type="text"
                        class="form-input w-full border border-red-300 rounded-md px-3 py-2 text-sm focus:ring-red-500 focus:border-red-500"
                        value={{this.deleteConfirmText}}
                        placeholder="DELETE"
                        {{on "input" this.updateDeleteConfirmText}}
                      />
                    </div>
                    <div class="flex items-center gap-3">
                      <button
                        type="button"
                        class="btn btn-danger"
                        disabled={{not this.canDelete}}
                        {{on "click" this.deleteAccount}}
                      >
                        Permanently delete my account
                      </button>
                      <button
                        type="button"
                        class="btn btn-outline"
                        {{on "click" this.toggleDeleteConfirm}}
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                {{else}}
                  <button
                    type="button"
                    class="btn btn-danger"
                    {{on "click" this.toggleDeleteConfirm}}
                  >
                    Delete my account
                  </button>
                {{/if}}
              </div>
            </div>
          </div>
        {{/if}}

        {{! Save Button }}
        {{#if this.isDirty}}
          <div class="save-bar fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-8 py-4 flex items-center justify-end gap-3 shadow-lg z-40">
            <span class="text-sm text-gray-500">You have unsaved changes</span>
            <button type="button" class="btn btn-outline" {{on "click" (fn (mut this.isDirty) false)}}>
              Discard
            </button>
            <button
              type="button"
              class="btn btn-primary"
              disabled={{this.isSaving}}
              {{on "click" this.saveSettings}}
            >
              {{#if this.isSaving}}
                <LoadingSpinner @size="sm" />
                Saving...
              {{else}}
                Save changes
              {{/if}}
            </button>
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}

// ─── Default Export: Dashboard Application ───────────────────────────────────

export default class DashboardApplication extends Component {
  @service router;
  @service store;
  @service session;
  @service notifications;

  @tracked sidebarOpen = true;
  @tracked activeView = 'dashboard';
  @tracked isLoading = false;
  @tracked globalSearchQuery = '';
  @tracked globalSearchOpen = false;
  @tracked showNotificationPanel = false;
  @tracked showUserMenu = false;
  @tracked showSettingsModal = false;
  @tracked showCreateModal = false;
  @tracked createModalType = null;

  @tracked dashboardData = [];
  @tracked recentActivity = [];
  @tracked notificationsList = [];
  @tracked unreadCount = 0;
  @tracked currentUser = null;

  @tracked chartPeriod = '7d';
  @tracked chartType = 'line';

  @tracked quickCreateName = '';
  @tracked quickCreateDescription = '';
  @tracked quickCreatePriority = PRIORITY_MEDIUM;
  @tracked quickCreateAssignee = null;
  @tracked quickCreateDueDate = null;
  @tracked quickCreateTags = [];

  @tracked selectedProject = null;
  @tracked projectList = [];
  @tracked teamMembers = [];

  get sidebarWidth() {
    return this.sidebarOpen ? SIDEBAR_WIDTH : SIDEBAR_COLLAPSED_WIDTH;
  }

  get navItems() {
    return [
      { id: 'dashboard', label: 'Dashboard', icon: 'D', badge: null },
      { id: 'projects', label: 'Projects', icon: 'P', badge: this.projectList.length },
      { id: 'tasks', label: 'Tasks', icon: 'T', badge: null },
      { id: 'team', label: 'Team', icon: 'G', badge: null },
      { id: 'reports', label: 'Reports', icon: 'R', badge: null },
      { id: 'calendar', label: 'Calendar', icon: 'C', badge: null },
      { id: 'messages', label: 'Messages', icon: 'M', badge: 3 },
      { id: 'settings', label: 'Settings', icon: 'S', badge: null },
    ];
  }

  get userMenuItems() {
    return [
      { label: 'Your Profile', action: 'profile', icon: 'U' },
      { label: 'Settings', action: 'settings', icon: 'S' },
      { label: 'Keyboard Shortcuts', action: 'shortcuts', icon: 'K', shortcut: '?' },
      { divider: true },
      { label: 'Help & Support', action: 'help', icon: 'H' },
      { label: 'API Documentation', action: 'docs', icon: 'D' },
      { divider: true },
      { label: 'Sign out', action: 'signout', icon: 'X', danger: true },
    ];
  }

  get breadcrumbItems() {
    const items = [{ label: 'Home', href: '/' }];
    if (this.activeView !== 'dashboard') {
      items.push({ label: capitalize(this.activeView), href: `/${this.activeView}` });
    }
    if (this.selectedProject) {
      items.push({ label: this.selectedProject.name, active: true });
    } else {
      items[items.length - 1].active = true;
    }
    return items;
  }

  get dashboardTabs() {
    return [
      { id: 'overview', label: 'Overview' },
      { id: 'analytics', label: 'Analytics' },
      { id: 'activity', label: 'Activity', count: this.recentActivity.length },
      { id: 'reports', label: 'Reports' },
    ];
  }

  get chartPeriodOptions() {
    return [
      { value: '24h', label: 'Last 24 hours' },
      { value: '7d', label: 'Last 7 days' },
      { value: '30d', label: 'Last 30 days' },
      { value: '90d', label: 'Last 90 days' },
      { value: '1y', label: 'Last year' },
    ];
  }

  get filteredNotifications() {
    return this.notificationsList.filter((n) => !n.dismissed);
  }

  get hasUnreadNotifications() {
    return this.unreadCount > 0;
  }

  get isQuickCreateValid() {
    return this.quickCreateName.trim().length > 0;
  }

  get sortedTeamMembers() {
    return sortBy(this.teamMembers, 'name', SORT_ASC);
  }

  get onlineTeamMembers() {
    return this.teamMembers.filter((m) => m.isOnline);
  }

  get offlineTeamMembers() {
    return this.teamMembers.filter((m) => !m.isOnline);
  }

  get projectProgress() {
    if (!this.selectedProject) return 0;
    const tasks = this.selectedProject.tasks || [];
    const completed = tasks.filter((t) => t.status === 'done').length;
    return computePercentage(completed, tasks.length);
  }

  @action
  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen;
  }

  @action
  setActiveView(viewId) {
    this.activeView = viewId;
    this.selectedProject = null;
  }

  @action
  handleGlobalSearch(event) {
    this.globalSearchQuery = event.target.value;
  }

  @action
  openGlobalSearch() {
    this.globalSearchOpen = true;
  }

  @action
  closeGlobalSearch() {
    this.globalSearchOpen = false;
    this.globalSearchQuery = '';
  }

  @action
  toggleNotificationPanel() {
    this.showNotificationPanel = !this.showNotificationPanel;
    if (this.showNotificationPanel) {
      this.showUserMenu = false;
    }
  }

  @action
  toggleUserMenu() {
    this.showUserMenu = !this.showUserMenu;
    if (this.showUserMenu) {
      this.showNotificationPanel = false;
    }
  }

  @action
  closeUserMenu() {
    this.showUserMenu = false;
  }

  @action
  closeNotificationPanel() {
    this.showNotificationPanel = false;
  }

  @action
  handleUserMenuAction(item) {
    this.showUserMenu = false;
    switch (item.action) {
      case 'profile':
        this.activeView = 'profile';
        break;
      case 'settings':
        this.showSettingsModal = true;
        break;
      case 'signout':
        if (this.args.onSignOut) this.args.onSignOut();
        break;
      default:
        break;
    }
  }

  @action
  dismissNotification(notification) {
    const idx = this.notificationsList.indexOf(notification);
    if (idx >= 0) {
      this.notificationsList = this.notificationsList.map((n, i) =>
        i === idx ? { ...n, dismissed: true } : n
      );
      this.unreadCount = Math.max(0, this.unreadCount - 1);
    }
  }

  @action
  markAllNotificationsRead() {
    this.notificationsList = this.notificationsList.map((n) => ({ ...n, read: true }));
    this.unreadCount = 0;
  }

  @action
  openCreateModal(type) {
    this.createModalType = type || 'task';
    this.showCreateModal = true;
    this.quickCreateName = '';
    this.quickCreateDescription = '';
    this.quickCreatePriority = PRIORITY_MEDIUM;
    this.quickCreateAssignee = null;
    this.quickCreateDueDate = null;
    this.quickCreateTags = [];
  }

  @action
  closeCreateModal() {
    this.showCreateModal = false;
    this.createModalType = null;
  }

  @action
  updateQuickCreateName(event) {
    this.quickCreateName = event.target.value;
  }

  @action
  updateQuickCreateDescription(event) {
    this.quickCreateDescription = event.target.value;
  }

  @action
  updateQuickCreatePriority(event) {
    this.quickCreatePriority = Number(event.target.value);
  }

  @action
  updateQuickCreateDueDate(event) {
    this.quickCreateDueDate = event.target.value;
  }

  @action
  async submitQuickCreate() {
    if (!this.isQuickCreateValid) return;
    this.isLoading = true;
    try {
      const payload = {
        id: generateId(),
        name: this.quickCreateName,
        description: this.quickCreateDescription,
        priority: this.quickCreatePriority,
        assignee: this.quickCreateAssignee,
        dueDate: this.quickCreateDueDate,
        tags: this.quickCreateTags,
        status: STATUS_PENDING,
        createdAt: new Date().toISOString(),
      };
      if (this.args.onCreate) {
        await this.args.onCreate(payload);
      }
      this.closeCreateModal();
    } finally {
      this.isLoading = false;
    }
  }

  @action
  selectProject(project) {
    this.selectedProject = project;
  }

  @action
  updateChartPeriod(event) {
    this.chartPeriod = event.target.value;
  }

  @action
  closeSettingsModal() {
    this.showSettingsModal = false;
  }

  @action
  handleEditRow(row) {
    if (this.args.onEditRow) {
      this.args.onEditRow(row);
    }
  }

  @action
  handleDeleteRow(row) {
    if (this.args.onDeleteRow) {
      this.args.onDeleteRow(row);
    }
  }

  @action
  handleBulkAction(actionType, ids) {
    if (this.args.onBulkAction) {
      this.args.onBulkAction(actionType, ids);
    }
  }

  @action
  handleTabChange(tabId) {
    this.activeView = tabId;
  }

  <template>
    <div class="dashboard-app flex h-screen bg-gray-100 overflow-hidden">
      {{! ── Sidebar ── }}
      <aside class="sidebar flex flex-col bg-gray-900 text-white transition-all duration-200"
        style="width: {{this.sidebarWidth}}px">
        {{! Sidebar Header }}
        <div class="sidebar-header flex items-center h-16 px-4 border-b border-gray-700">
          {{#if this.sidebarOpen}}
            <div class="flex items-center gap-3">
              <div class="logo w-8 h-8 bg-indigo-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">
                AP
              </div>
              <span class="sidebar-title text-base font-semibold">AppName</span>
            </div>
          {{else}}
            <div class="logo w-8 h-8 bg-indigo-500 rounded-lg flex items-center justify-center text-white font-bold text-sm mx-auto">
              AP
            </div>
          {{/if}}
        </div>

        {{! Sidebar Search }}
        {{#if this.sidebarOpen}}
          <div class="sidebar-search px-3 py-3">
            <button
              type="button"
              class="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-400 bg-gray-800 rounded-md hover:bg-gray-700 transition-colors"
              {{on "click" this.openGlobalSearch}}
            >
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              Search...
              <span class="ml-auto text-xs bg-gray-700 px-1.5 py-0.5 rounded">Cmd+K</span>
            </button>
          </div>
        {{/if}}

        {{! Navigation Items }}
        <nav class="sidebar-nav flex-1 overflow-y-auto px-2 py-2">
          <ul class="space-y-1">
            {{#each this.navItems as |item|}}
              <li>
                <button
                  type="button"
                  class="nav-item w-full flex items-center px-3 py-2.5 rounded-md text-sm font-medium transition-colors
                    {{if (eq item.id this.activeView)
                      'bg-gray-800 text-white'
                      'text-gray-300 hover:bg-gray-800 hover:text-white'}}"
                  {{on "click" (fn this.setActiveView item.id)}}
                  {{tooltip item.label}}
                >
                  <span class="nav-icon flex-shrink-0 w-5 h-5 flex items-center justify-center text-base">
                    {{item.icon}}
                  </span>
                  {{#if this.sidebarOpen}}
                    <span class="nav-label ml-3">{{item.label}}</span>
                    {{#if item.badge}}
                      <span class="nav-badge ml-auto px-2 py-0.5 text-xs bg-indigo-600 text-white rounded-full">
                        {{item.badge}}
                      </span>
                    {{/if}}
                  {{/if}}
                </button>
              </li>
            {{/each}}
          </ul>
        </nav>

        {{! Online Team Members }}
        {{#if this.sidebarOpen}}
          <div class="sidebar-team px-3 py-3 border-t border-gray-700">
            <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
              Online ({{this.onlineTeamMembers.length}})
            </h4>
            <ul class="space-y-2">
              {{#each this.onlineTeamMembers as |member|}}
                <li class="flex items-center gap-2">
                  <Avatar @initials={{getInitials member.name}} @size="sm" @online={{true}} />
                  <span class="text-sm text-gray-300 truncate">{{member.name}}</span>
                </li>
              {{/each}}
            </ul>
          </div>
        {{/if}}

        {{! Sidebar Toggle }}
        <div class="sidebar-toggle border-t border-gray-700 p-2">
          <button
            type="button"
            class="w-full flex items-center justify-center py-2 text-gray-400 hover:text-white rounded-md hover:bg-gray-800 transition-colors"
            {{on "click" this.toggleSidebar}}
          >
            {{#if this.sidebarOpen}}
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
              </svg>
            {{else}}
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
              </svg>
            {{/if}}
          </button>
        </div>
      </aside>

      {{! ── Main Content Area ── }}
      <div class="main-content flex-1 flex flex-col overflow-hidden">
        {{! Top Bar }}
        <header class="topbar flex items-center justify-between h-16 px-6 bg-white border-b border-gray-200 flex-shrink-0">
          <div class="topbar-left flex items-center gap-4">
            <Breadcrumb @items={{this.breadcrumbItems}} />
          </div>
          <div class="topbar-right flex items-center gap-3">
            {{! Quick Create Button }}
            <button
              type="button"
              class="quick-create inline-flex items-center px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-md hover:bg-indigo-700 transition-colors"
              {{on "click" (fn this.openCreateModal "task")}}
            >
              <svg class="w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              New
            </button>

            {{! Chart Period Selector }}
            <select
              class="chart-period-select border border-gray-300 rounded-md text-sm py-1.5 px-2 text-gray-700"
              {{on "change" this.updateChartPeriod}}
            >
              {{#each this.chartPeriodOptions as |opt|}}
                <option value={{opt.value}} selected={{eq opt.value this.chartPeriod}}>{{opt.label}}</option>
              {{/each}}
            </select>

            {{! Notification Bell }}
            <div class="notification-trigger relative">
              <button
                type="button"
                class="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors relative"
                {{on "click" this.toggleNotificationPanel}}
              >
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                {{#if this.hasUnreadNotifications}}
                  <span class="notification-badge absolute -top-0.5 -right-0.5 w-4 h-4 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                    {{this.unreadCount}}
                  </span>
                {{/if}}
              </button>

              {{! Notification Dropdown }}
              {{#if this.showNotificationPanel}}
                <div class="notification-panel absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-xl border border-gray-200 z-50"
                  {{onClickOutside this.closeNotificationPanel}}>
                  <div class="notification-header flex items-center justify-between px-4 py-3 border-b border-gray-200">
                    <h3 class="text-sm font-semibold text-gray-900">Notifications</h3>
                    <button
                      type="button"
                      class="text-xs text-indigo-600 hover:text-indigo-800"
                      {{on "click" this.markAllNotificationsRead}}
                    >
                      Mark all as read
                    </button>
                  </div>
                  <div class="notification-list max-h-96 overflow-y-auto">
                    {{#each this.filteredNotifications as |notification|}}
                      <div class="notification-item flex items-start gap-3 px-4 py-3 border-b border-gray-100 hover:bg-gray-50 transition-colors
                        {{if (not notification.read) 'bg-blue-50'}}">
                        <div class="notification-icon flex-shrink-0 mt-0.5">
                          {{#if (eq notification.type "info")}}
                            <span class="w-2 h-2 bg-blue-500 rounded-full inline-block"></span>
                          {{else if (eq notification.type "warning")}}
                            <span class="w-2 h-2 bg-yellow-500 rounded-full inline-block"></span>
                          {{else if (eq notification.type "error")}}
                            <span class="w-2 h-2 bg-red-500 rounded-full inline-block"></span>
                          {{else}}
                            <span class="w-2 h-2 bg-green-500 rounded-full inline-block"></span>
                          {{/if}}
                        </div>
                        <div class="notification-body flex-1 min-w-0">
                          <p class="text-sm text-gray-900 {{if (not notification.read) 'font-medium'}}">
                            {{notification.title}}
                          </p>
                          <p class="text-xs text-gray-500 mt-0.5 truncate">{{notification.message}}</p>
                          <p class="text-xs text-gray-400 mt-1">{{formatRelativeTime notification.createdAt}}</p>
                        </div>
                        <button
                          type="button"
                          class="notification-dismiss flex-shrink-0 text-gray-400 hover:text-gray-600"
                          {{on "click" (fn this.dismissNotification notification)}}
                        >
                          <svg class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" />
                          </svg>
                        </button>
                      </div>
                    {{else}}
                      <div class="py-8 text-center">
                        <p class="text-sm text-gray-500">No notifications</p>
                      </div>
                    {{/each}}
                  </div>
                  <div class="notification-footer px-4 py-2 border-t border-gray-200 text-center">
                    <button type="button" class="text-sm text-indigo-600 hover:text-indigo-800 font-medium">
                      View all notifications
                    </button>
                  </div>
                </div>
              {{/if}}
            </div>

            {{! User Menu }}
            <DropdownMenu
              @isOpen={{this.showUserMenu}}
              @items={{this.userMenuItems}}
              @onClose={{this.closeUserMenu}}
              @onSelect={{this.handleUserMenuAction}}
            >
              <:trigger>
                <button
                  type="button"
                  class="user-menu-trigger flex items-center gap-2 p-1 rounded-full hover:bg-gray-100 transition-colors"
                  {{on "click" this.toggleUserMenu}}
                >
                  <Avatar
                    @initials={{if this.currentUser (getInitials this.currentUser.name) "??"}}
                    @size="sm"
                    @online={{true}}
                  />
                  {{#if this.sidebarOpen}}
                    <span class="text-sm font-medium text-gray-700 hidden lg:block">
                      {{if this.currentUser this.currentUser.name "User"}}
                    </span>
                  {{/if}}
                </button>
              </:trigger>
            </DropdownMenu>
          </div>
        </header>

        {{! Page Content }}
        <main class="page-content flex-1 overflow-y-auto p-6">
          {{#if this.isLoading}}
            <div class="flex items-center justify-center h-64">
              <LoadingSpinner @size="lg" @message="Loading dashboard data..." />
            </div>
          {{else}}
            {{! Dashboard View }}
            {{#if (eq this.activeView "dashboard")}}
              <div class="dashboard-view space-y-6">
                <div class="dashboard-header flex items-center justify-between">
                  <div>
                    <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
                    <p class="text-sm text-gray-500 mt-1">Welcome back! Here is what is happening today.</p>
                  </div>
                </div>

                <TabBar
                  @tabs={{this.dashboardTabs}}
                  @activeTab={{this.activeView}}
                  @onTabChange={{this.handleTabChange}}
                />

                {{! Charts Row }}
                <div class="charts-row grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <Card @header="Revenue Overview">
                    <:headerActions>
                      <select class="text-xs border border-gray-300 rounded px-2 py-1" {{on "change" this.updateChartPeriod}}>
                        {{#each this.chartPeriodOptions as |opt|}}
                          <option value={{opt.value}}>{{opt.label}}</option>
                        {{/each}}
                      </select>
                    </:headerActions>
                    <div class="chart-placeholder h-64 bg-gray-50 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-200">
                      <div class="text-center text-gray-400">
                        <svg class="w-12 h-12 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                        </svg>
                        <p class="text-sm">Revenue chart placeholder</p>
                      </div>
                    </div>
                  </Card>

                  <Card @header="User Growth">
                    <div class="chart-placeholder h-64 bg-gray-50 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-200">
                      <div class="text-center text-gray-400">
                        <svg class="w-12 h-12 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        <p class="text-sm">User growth chart placeholder</p>
                      </div>
                    </div>
                  </Card>
                </div>

                {{! Recent Activity }}
                <Card @header="Recent Activity">
                  <div class="activity-feed space-y-4">
                    {{#each this.recentActivity as |activity|}}
                      <div class="activity-item flex items-start gap-3">
                        <Avatar @initials={{getInitials activity.user}} @size="sm" />
                        <div class="activity-content flex-1">
                          <p class="text-sm">
                            <span class="font-medium text-gray-900">{{activity.user}}</span>
                            <span class="text-gray-600">{{activity.action}}</span>
                            <span class="font-medium text-indigo-600">{{activity.target}}</span>
                          </p>
                          <p class="text-xs text-gray-400 mt-0.5">{{formatRelativeTime activity.timestamp}}</p>
                        </div>
                      </div>
                    {{else}}
                      <EmptyState
                        @title="No recent activity"
                        @description="Activity will appear here when team members take actions."
                      />
                    {{/each}}
                  </div>
                </Card>

                {{! Project Cards }}
                {{#if this.projectList.length}}
                  <div class="projects-section">
                    <h2 class="text-lg font-semibold text-gray-900 mb-4">Active Projects</h2>
                    <div class="project-grid grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {{#each this.projectList as |project|}}
                        <Card @hoverable={{true}}>
                          <div class="project-card-content" {{on "click" (fn this.selectProject project)}} role="button">
                            <div class="flex items-center justify-between mb-3">
                              <h3 class="text-sm font-semibold text-gray-900">{{project.name}}</h3>
                              <Badge @variant={{getStatusColor project.status}}>{{capitalize project.status}}</Badge>
                            </div>
                            <p class="text-xs text-gray-500 mb-3 line-clamp-2">{{truncate project.description 80}}</p>
                            <ProgressBar @value={{project.progress}} @color="indigo" />
                            <div class="flex items-center justify-between mt-3">
                              <div class="flex -space-x-2">
                                {{#each project.members as |member|}}
                                  <Avatar @initials={{getInitials member.name}} @size="sm" />
                                {{/each}}
                              </div>
                              <span class="text-xs text-gray-400">Due {{formatDate project.dueDate}}</span>
                            </div>
                          </div>
                        </Card>
                      {{/each}}
                    </div>
                  </div>
                {{/if}}
              </div>
            {{/if}}

            {{! Tasks View }}
            {{#if (eq this.activeView "tasks")}}
              <div class="tasks-view">
                <div class="tasks-header flex items-center justify-between mb-6">
                  <div>
                    <h1 class="text-2xl font-bold text-gray-900">Tasks</h1>
                    <p class="text-sm text-gray-500 mt-1">Manage and track all your tasks.</p>
                  </div>
                  <button
                    type="button"
                    class="btn btn-primary"
                    {{on "click" (fn this.openCreateModal "task")}}
                  >
                    Create Task
                  </button>
                </div>

                <DataTableManager
                  @data={{this.dashboardData}}
                  @onEdit={{this.handleEditRow}}
                  @onDelete={{this.handleDeleteRow}}
                  @onBulkAction={{this.handleBulkAction}}
                />
              </div>
            {{/if}}

            {{! Settings View }}
            {{#if (eq this.activeView "settings")}}
              <div class="settings-view">
                <div class="settings-header mb-6">
                  <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
                  <p class="text-sm text-gray-500 mt-1">Manage your account and application preferences.</p>
                </div>
                <Card @noPadding={{true}}>
                  <SettingsPanel />
                </Card>
              </div>
            {{/if}}

            {{! Team View }}
            {{#if (eq this.activeView "team")}}
              <div class="team-view">
                <div class="team-header flex items-center justify-between mb-6">
                  <div>
                    <h1 class="text-2xl font-bold text-gray-900">Team</h1>
                    <p class="text-sm text-gray-500 mt-1">{{this.teamMembers.length}} members</p>
                  </div>
                  <button type="button" class="btn btn-primary">Invite Member</button>
                </div>

                <div class="team-grid grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                  {{#each this.sortedTeamMembers as |member|}}
                    <Card @hoverable={{true}}>
                      <div class="team-member-card text-center">
                        <Avatar @initials={{getInitials member.name}} @size="xl" @online={{member.isOnline}} />
                        <h3 class="mt-3 text-sm font-semibold text-gray-900">{{member.name}}</h3>
                        <p class="text-xs text-gray-500">{{member.role}}</p>
                        <p class="text-xs text-gray-400 mt-1">{{member.email}}</p>
                        <div class="mt-3 flex items-center justify-center gap-2">
                          <Badge @variant={{if member.isOnline "success" "default"}}>
                            {{if member.isOnline "Online" "Offline"}}
                          </Badge>
                        </div>
                        <div class="mt-4 flex justify-center gap-2">
                          <button type="button" class="btn btn-sm btn-outline">Message</button>
                          <button type="button" class="btn btn-sm btn-outline">Profile</button>
                        </div>
                      </div>
                    </Card>
                  {{else}}
                    <div class="col-span-full">
                      <EmptyState
                        @title="No team members"
                        @description="Start by inviting your first team member."
                        @actionLabel="Invite Member"
                        @onAction={{fn this.openCreateModal "member"}}
                      />
                    </div>
                  {{/each}}
                </div>
              </div>
            {{/if}}

            {{! Reports View }}
            {{#if (eq this.activeView "reports")}}
              <div class="reports-view space-y-6">
                <div class="reports-header">
                  <h1 class="text-2xl font-bold text-gray-900">Reports</h1>
                  <p class="text-sm text-gray-500 mt-1">Analytics and performance reports.</p>
                </div>

                <div class="reports-grid grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <Card @header="Performance Metrics">
                    <div class="space-y-4">
                      <ProgressBar @label="CPU Usage" @value={{72}} @color="indigo" />
                      <ProgressBar @label="Memory Usage" @value={{58}} @color="green" />
                      <ProgressBar @label="Disk Usage" @value={{85}} @color="yellow" />
                      <ProgressBar @label="Network I/O" @value={{43}} @color="indigo" />
                    </div>
                  </Card>

                  <Card @header="Activity Breakdown">
                    <div class="chart-placeholder h-48 bg-gray-50 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-200">
                      <p class="text-sm text-gray-400">Pie chart placeholder</p>
                    </div>
                  </Card>

                  <Card @header="Weekly Summary">
                    <div class="weekly-stats space-y-3">
                      <div class="flex items-center justify-between py-2 border-b border-gray-100">
                        <span class="text-sm text-gray-600">Tasks completed</span>
                        <span class="text-sm font-semibold text-gray-900">47</span>
                      </div>
                      <div class="flex items-center justify-between py-2 border-b border-gray-100">
                        <span class="text-sm text-gray-600">Tasks created</span>
                        <span class="text-sm font-semibold text-gray-900">62</span>
                      </div>
                      <div class="flex items-center justify-between py-2 border-b border-gray-100">
                        <span class="text-sm text-gray-600">Team velocity</span>
                        <span class="text-sm font-semibold text-gray-900">34 pts</span>
                      </div>
                      <div class="flex items-center justify-between py-2 border-b border-gray-100">
                        <span class="text-sm text-gray-600">Avg resolution time</span>
                        <span class="text-sm font-semibold text-gray-900">2.3 days</span>
                      </div>
                      <div class="flex items-center justify-between py-2">
                        <span class="text-sm text-gray-600">Customer satisfaction</span>
                        <span class="text-sm font-semibold text-green-600">94%</span>
                      </div>
                    </div>
                  </Card>

                  <Card @header="Top Contributors">
                    <div class="contributors-list space-y-3">
                      {{#each this.sortedTeamMembers as |member index|}}
                        <div class="contributor-item flex items-center gap-3">
                          <span class="contributor-rank text-sm font-bold text-gray-400 w-6">{{index}}</span>
                          <Avatar @initials={{getInitials member.name}} @size="sm" />
                          <div class="flex-1">
                            <p class="text-sm font-medium text-gray-900">{{member.name}}</p>
                            <ProgressBar @value={{member.score}} />
                          </div>
                          <span class="text-sm font-semibold text-gray-700">{{member.score}} pts</span>
                        </div>
                      {{/each}}
                    </div>
                  </Card>
                </div>
              </div>
            {{/if}}
          {{/if}}
        </main>
      </div>

      {{! ── Global Search Modal ── }}
      <Modal
        @isOpen={{this.globalSearchOpen}}
        @title="Search"
        @size="lg"
        @onClose={{this.closeGlobalSearch}}
      >
        <div class="global-search-content">
          <SearchInput
            @value={{this.globalSearchQuery}}
            @onInput={{this.handleGlobalSearch}}
            @onClear={{this.closeGlobalSearch}}
            @placeholder="Search tasks, projects, team members..."
          />
          {{#if this.globalSearchQuery}}
            <div class="search-results mt-4 space-y-2">
              <p class="text-xs text-gray-500 uppercase tracking-wider mb-2">Results</p>
              <div class="search-result-item flex items-center gap-3 px-3 py-2 rounded-md hover:bg-gray-100 cursor-pointer">
                <span class="text-gray-400">T</span>
                <div>
                  <p class="text-sm font-medium text-gray-900">Sample task result</p>
                  <p class="text-xs text-gray-500">in Project Alpha</p>
                </div>
              </div>
              <div class="search-result-item flex items-center gap-3 px-3 py-2 rounded-md hover:bg-gray-100 cursor-pointer">
                <span class="text-gray-400">P</span>
                <div>
                  <p class="text-sm font-medium text-gray-900">Sample project result</p>
                  <p class="text-xs text-gray-500">3 members</p>
                </div>
              </div>
            </div>
          {{else}}
            <div class="search-hints mt-4">
              <p class="text-xs text-gray-500 uppercase tracking-wider mb-2">Quick actions</p>
              <div class="grid grid-cols-2 gap-2">
                <button type="button" class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 rounded-md hover:bg-gray-100">
                  <span class="text-gray-400">+</span> Create task
                </button>
                <button type="button" class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 rounded-md hover:bg-gray-100">
                  <span class="text-gray-400">+</span> Create project
                </button>
                <button type="button" class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 rounded-md hover:bg-gray-100">
                  <span class="text-gray-400">@</span> Find member
                </button>
                <button type="button" class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 rounded-md hover:bg-gray-100">
                  <span class="text-gray-400">#</span> Go to channel
                </button>
              </div>
            </div>
          {{/if}}
        </div>
      </Modal>

      {{! ── Quick Create Modal ── }}
      <Modal
        @isOpen={{this.showCreateModal}}
        @title={{if (eq this.createModalType "task") "Create New Task" "Create New Item"}}
        @size="lg"
        @onClose={{this.closeCreateModal}}
      >
        <div class="create-form space-y-4">
          <div class="form-group">
            <label for="create-name" class="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input
              id="create-name"
              type="text"
              class="form-input w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500"
              value={{this.quickCreateName}}
              placeholder="Enter a name..."
              {{on "input" this.updateQuickCreateName}}
              {{autoFocus}}
            />
          </div>
          <div class="form-group">
            <label for="create-desc" class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              id="create-desc"
              rows="3"
              class="form-textarea w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Add a description..."
              {{on "input" this.updateQuickCreateDescription}}
            >{{this.quickCreateDescription}}</textarea>
          </div>
          <div class="form-row grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="form-group">
              <label for="create-priority" class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
              <select
                id="create-priority"
                class="form-select w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                {{on "change" this.updateQuickCreatePriority}}
              >
                <option value="1">Low</option>
                <option value="2" selected>Medium</option>
                <option value="3">High</option>
                <option value="4">Critical</option>
              </select>
            </div>
            <div class="form-group">
              <label for="create-due" class="block text-sm font-medium text-gray-700 mb-1">Due Date</label>
              <input
                id="create-due"
                type="date"
                class="form-input w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
                {{on "change" this.updateQuickCreateDueDate}}
              />
            </div>
          </div>
        </div>
        <:footer>
          <button
            type="button"
            class="btn btn-outline"
            {{on "click" this.closeCreateModal}}
          >
            Cancel
          </button>
          <button
            type="button"
            class="btn btn-primary"
            disabled={{or (not this.isQuickCreateValid) this.isLoading}}
            {{on "click" this.submitQuickCreate}}
          >
            {{#if this.isLoading}}
              <LoadingSpinner @size="sm" />
              Creating...
            {{else}}
              Create
            {{/if}}
          </button>
        </:footer>
      </Modal>

      {{! ── Settings Modal ── }}
      <Modal
        @isOpen={{this.showSettingsModal}}
        @title="Settings"
        @size="xl"
        @onClose={{this.closeSettingsModal}}
      >
        <SettingsPanel />
      </Modal>
    </div>
  </template>
}
