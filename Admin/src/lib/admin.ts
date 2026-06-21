import { supabase } from "@/lib/supabase";

export type OverviewDatePreset = "today" | "7d" | "30d" | "all" | "custom";

export type OverviewDateRange = {
  from: string | null;
  to: string | null;
};

export type AdminOverviewStats = {
  total_requests: number;
  requests_today: number;
  completed_requests: number;
  active_requests: number;
  open_complaints: number;
  pending_workers: number;
  total_customers: number;
  active_workers: number;
  total_offers: number;
  offers_in_period: number;
  status_counts: Record<string, number>;
  is_filtered: boolean;
};

export type AdminDailyTrendPoint = {
  day: string;
  total: number;
  completed: number;
};

export type OverviewFilters = {
  dateRange: OverviewDateRange;
  status: string | null;
  requestLimit?: number;
};

export type AdminRecentRequest = {
  id: string;
  status: string;
  created_at: string;
  area: string;
  governorate: string;
  service_name: string;
  category_name: string;
  customer_name: string;
  worker_name: string;
  offer_count: number;
  final_price: number | null;
  payment_method: string | null;
};

const requestStatusLabels: Record<string, string> = {
  new: "جديد",
  offered: "به عروض",
  accepted: "مقبول",
  on_the_way: "في الطريق",
  in_progress: "قيد التنفيذ",
  completed: "مكتمل",
  cancelled: "ملغي",
  complaint: "شكوى",
};

export function getRequestStatusLabel(status: string) {
  return requestStatusLabels[status] ?? status;
}

export function getOverviewDateRange(
  preset: OverviewDatePreset,
  customFrom = "",
  customTo = "",
): OverviewDateRange {
  const now = new Date();

  const startOfUtcDay = (date: Date) =>
    new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
    ).toISOString();

  const endOfUtcDay = (date: Date) =>
    new Date(
      Date.UTC(
        date.getUTCFullYear(),
        date.getUTCMonth(),
        date.getUTCDate(),
        23,
        59,
        59,
        999,
      ),
    ).toISOString();

  switch (preset) {
    case "today":
      return { from: startOfUtcDay(now), to: endOfUtcDay(now) };
    case "7d": {
      const from = new Date(now);
      from.setUTCDate(from.getUTCDate() - 6);
      return { from: startOfUtcDay(from), to: endOfUtcDay(now) };
    }
    case "30d": {
      const from = new Date(now);
      from.setUTCDate(from.getUTCDate() - 29);
      return { from: startOfUtcDay(from), to: endOfUtcDay(now) };
    }
    case "custom": {
      const from = customFrom ? startOfUtcDay(new Date(customFrom)) : null;
      const to = customTo ? endOfUtcDay(new Date(customTo)) : null;
      return { from, to };
    }
    case "all":
    default:
      return { from: null, to: null };
  }
}

export async function loadOverviewStats(dateRange: OverviewDateRange) {
  const { data, error } = await supabase.rpc("admin_overview_stats", {
    p_from: dateRange.from,
    p_to: dateRange.to,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? {
    total_requests: 0,
    requests_today: 0,
    completed_requests: 0,
    active_requests: 0,
    open_complaints: 0,
    pending_workers: 0,
    total_customers: 0,
    active_workers: 0,
    total_offers: 0,
    offers_in_period: 0,
    status_counts: {},
    is_filtered: false,
  }) as AdminOverviewStats;
}

export async function loadOverviewDailyTrend(dateRange: OverviewDateRange) {
  const { data, error } = await supabase.rpc("admin_overview_daily_trend", {
    p_from: dateRange.from,
    p_to: dateRange.to,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminDailyTrendPoint[];
}

export async function loadRecentRequests(filters: OverviewFilters) {
  const { data, error } = await supabase.rpc("admin_list_recent_requests", {
    p_limit: filters.requestLimit ?? 20,
    p_from: filters.dateRange.from,
    p_to: filters.dateRange.to,
    p_status: filters.status,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminRecentRequest[];
}

export type PendingWorker = {
  user_id: string;
  full_name: string;
  phone: string;
  governorate: string;
  area: string;
  address: string;
  profession: string;
  years_experience: number;
  bio: string;
  created_at: string;
};

export async function loadPendingWorkers() {
  const { data, error } = await supabase.rpc("admin_list_pending_workers");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as PendingWorker[];
}

export async function approveWorker(workerId: string) {
  const { error } = await supabase.rpc("admin_approve_worker", {
    p_worker_id: workerId,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function rejectWorker(workerId: string) {
  const { error } = await supabase.rpc("admin_reject_worker", {
    p_worker_id: workerId,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export type AdminArea = {
  id: number;
  governorate: string;
  name: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
};

export type CreateAreaInput = {
  governorate: string;
  name: string;
  sortOrder: number;
};

export type UpdateAreaInput = {
  areaId: number;
  governorate: string;
  name: string;
  sortOrder: number;
  isActive: boolean;
};

export type AdminComplaint = {
  id: string;
  request_id: string;
  category: string;
  description: string;
  status: string;
  created_at: string;
  customer_name: string;
  customer_phone: string;
  worker_name: string;
  worker_phone: string;
  service_name: string;
  area: string;
};

export type ComplaintStatus = "open" | "in_review" | "resolved" | "dismissed";

const complaintCategoryLabels: Record<string, string> = {
  poor_quality: "جودة الشغل ضعيفة",
  no_show: "الصنايعي ما حضرش",
  overcharge: "زيادة في السعر",
  behavior: "سلوك غير لائق",
  other: "سبب آخر",
};

const complaintStatusLabels: Record<ComplaintStatus, string> = {
  open: "جديدة",
  in_review: "قيد المراجعة",
  resolved: "تم الحل",
  dismissed: "مرفوضة",
};

export function getComplaintCategoryLabel(category: string) {
  return complaintCategoryLabels[category] ?? category;
}

export function getComplaintStatusLabel(status: string) {
  return complaintStatusLabels[status as ComplaintStatus] ?? status;
}

export async function loadComplaints() {
  const { data, error } = await supabase.rpc("admin_list_complaints");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminComplaint[];
}

export async function updateComplaintStatus(
  complaintId: string,
  status: ComplaintStatus,
) {
  const { error } = await supabase.rpc("admin_update_complaint_status", {
    p_complaint_id: complaintId,
    p_status: status,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadAreas() {
  const { data, error } = await supabase.rpc("admin_list_areas");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminArea[];
}

export async function createArea(input: CreateAreaInput) {
  const { error } = await supabase.rpc("admin_create_area", {
    p_governorate: input.governorate.trim(),
    p_name: input.name.trim(),
    p_sort_order: input.sortOrder,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function updateArea(input: UpdateAreaInput) {
  const { error } = await supabase.rpc("admin_update_area", {
    p_area_id: input.areaId,
    p_governorate: input.governorate.trim(),
    p_name: input.name.trim(),
    p_sort_order: input.sortOrder,
    p_is_active: input.isActive,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export type AdminUser = {
  user_id: string;
  full_name: string;
  phone: string;
  role: "customer" | "worker";
  governorate: string;
  area: string;
  status: "active" | "pending" | "suspended";
  profession: string;
  approval_status: string;
  created_at: string;
};

export type UserStatusFilter = "active" | "pending" | "suspended" | null;
export type UserRoleFilter = "customer" | "worker" | null;

export type AdminCategory = {
  id: number;
  name: string;
  sort_order: number;
  is_active: boolean;
  service_count: number;
  active_service_count: number;
  created_at: string;
};

export type AdminService = {
  id: number;
  category_id: number;
  category_name: string;
  name: string;
  min_price: number;
  max_price: number;
  is_active: boolean;
  created_at: string;
};

export type CreateCategoryInput = {
  name: string;
  sortOrder: number;
};

export type UpdateCategoryInput = {
  categoryId: number;
  name: string;
  sortOrder: number;
  isActive: boolean;
};

export type CreateServiceInput = {
  categoryId: number;
  name: string;
  minPrice: number;
  maxPrice: number;
};

export type UpdateServiceInput = {
  serviceId: number;
  categoryId: number;
  name: string;
  minPrice: number;
  maxPrice: number;
  isActive: boolean;
};

const userRoleLabels: Record<AdminUser["role"], string> = {
  customer: "عميل",
  worker: "صنايعي",
};

const userStatusLabels: Record<AdminUser["status"], string> = {
  active: "نشط",
  pending: "بانتظار الاعتماد",
  suspended: "موقوف",
};

export function getUserRoleLabel(role: string) {
  return userRoleLabels[role as AdminUser["role"]] ?? role;
}

export function getUserStatusLabel(status: string) {
  return userStatusLabels[status as AdminUser["status"]] ?? status;
}

export async function loadUsers(filters: {
  role: UserRoleFilter;
  status: UserStatusFilter;
}) {
  const { data, error } = await supabase.rpc("admin_list_users", {
    p_role: filters.role,
    p_status: filters.status,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminUser[];
}

export async function updateUserStatus(
  userId: string,
  status: "active" | "suspended",
) {
  const { error } = await supabase.rpc("admin_update_user_status", {
    p_user_id: userId,
    p_status: status,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadCategories() {
  const { data, error } = await supabase.rpc("admin_list_categories");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminCategory[];
}

export async function createCategory(input: CreateCategoryInput) {
  const { error } = await supabase.rpc("admin_create_category", {
    p_name: input.name.trim(),
    p_sort_order: input.sortOrder,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function updateCategory(input: UpdateCategoryInput) {
  const { error } = await supabase.rpc("admin_update_category", {
    p_category_id: input.categoryId,
    p_name: input.name.trim(),
    p_sort_order: input.sortOrder,
    p_is_active: input.isActive,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadServices(categoryId: number | null = null) {
  const { data, error } = await supabase.rpc("admin_list_services", {
    p_category_id: categoryId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminService[];
}

export async function createService(input: CreateServiceInput) {
  const { error } = await supabase.rpc("admin_create_service", {
    p_category_id: input.categoryId,
    p_name: input.name.trim(),
    p_min_price: input.minPrice,
    p_max_price: input.maxPrice,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function updateService(input: UpdateServiceInput) {
  const { error } = await supabase.rpc("admin_update_service", {
    p_service_id: input.serviceId,
    p_category_id: input.categoryId,
    p_name: input.name.trim(),
    p_min_price: input.minPrice,
    p_max_price: input.maxPrice,
    p_is_active: input.isActive,
  });

  if (error) {
    throw new Error(error.message);
  }
}
