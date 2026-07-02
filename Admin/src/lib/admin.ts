import { supabase } from "@/lib/supabase";
import {
  buildQuery,
  getAccessToken,
  handyApiRequest,
  isHandyApiConfigured,
} from "@/lib/handy-api";

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminOverviewStats>(
      token,
      "GET",
      `/v1/admin/overview/stats${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
      })}`,
    );
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminDailyTrendPoint[]>(
      token,
      "GET",
      `/v1/admin/overview/trend${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
      })}`,
    );
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminRecentRequest[]>(
      token,
      "GET",
      `/v1/admin/requests/recent${buildQuery({
        limit: filters.requestLimit ?? 20,
        from: filters.dateRange.from,
        to: filters.dateRange.to,
        status: filters.status,
      })}`,
    );
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<PendingWorker[]>(
      token,
      "GET",
      "/v1/admin/workers/pending",
    );
  }

  const { data, error } = await supabase.rpc("admin_list_pending_workers");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as PendingWorker[];
}

export async function approveWorker(workerId: string) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "POST", `/v1/admin/workers/${workerId}/approve`);
    return;
  }

  const { error } = await supabase.rpc("admin_approve_worker", {
    p_worker_id: workerId,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function rejectWorker(workerId: string) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "POST", `/v1/admin/workers/${workerId}/reject`);
    return;
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminComplaint[]>(token, "GET", "/v1/admin/complaints");
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/complaints/${complaintId}`, {
      status,
    });
    return;
  }

  const { error } = await supabase.rpc("admin_update_complaint_status", {
    p_complaint_id: complaintId,
    p_status: status,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export type AdminReview = {
  id: string;
  request_id: string;
  worker_id: string;
  worker_name: string;
  worker_phone: string;
  customer_id: string;
  customer_name: string;
  customer_phone: string;
  rating: number;
  comment: string;
  is_hidden: boolean;
  created_at: string;
  service_name: string;
  area: string;
};

export type ReviewFilters = {
  workerId?: string | null;
  minRating?: number | null;
  maxRating?: number | null;
  includeHidden?: boolean;
  limit?: number;
};

export async function loadReviews(filters: ReviewFilters = {}) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminReview[]>(
      token,
      "GET",
      `/v1/admin/reviews${buildQuery({
        worker_id: filters.workerId,
        min_rating: filters.minRating,
        max_rating: filters.maxRating,
        include_hidden: String(filters.includeHidden ?? true),
        limit: filters.limit ?? 50,
      })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_list_reviews", {
    p_worker_id: filters.workerId ?? null,
    p_min_rating: filters.minRating ?? null,
    p_max_rating: filters.maxRating ?? null,
    p_include_hidden: filters.includeHidden ?? true,
    p_limit: filters.limit ?? 50,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminReview[];
}

export async function updateReviewVisibility(
  reviewId: string,
  isHidden: boolean,
) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/reviews/${reviewId}`, {
      is_hidden: isHidden,
    });
    return;
  }

  const { error } = await supabase.rpc("admin_update_review_visibility", {
    p_review_id: reviewId,
    p_is_hidden: isHidden,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadAreas() {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminArea[]>(token, "GET", "/v1/admin/areas");
  }

  const { data, error } = await supabase.rpc("admin_list_areas");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminArea[];
}

export async function createArea(input: CreateAreaInput) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "POST", "/v1/admin/areas", {
      governorate: input.governorate.trim(),
      name: input.name.trim(),
      sort_order: input.sortOrder,
    });
    return;
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/areas/${input.areaId}`, {
      governorate: input.governorate.trim(),
      name: input.name.trim(),
      sort_order: input.sortOrder,
      is_active: input.isActive,
    });
    return;
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminUser[]>(
      token,
      "GET",
      `/v1/admin/users${buildQuery({
        role: filters.role,
        status: filters.status,
      })}`,
    );
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/users/${userId}/status`, {
      status,
    });
    return;
  }

  const { error } = await supabase.rpc("admin_update_user_status", {
    p_user_id: userId,
    p_status: status,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadCategories() {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminCategory[]>(token, "GET", "/v1/admin/categories");
  }

  const { data, error } = await supabase.rpc("admin_list_categories");

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminCategory[];
}

export async function createCategory(input: CreateCategoryInput) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "POST", "/v1/admin/categories", {
      name: input.name.trim(),
      sort_order: input.sortOrder,
    });
    return;
  }

  const { error } = await supabase.rpc("admin_create_category", {
    p_name: input.name.trim(),
    p_sort_order: input.sortOrder,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function updateCategory(input: UpdateCategoryInput) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/categories/${input.categoryId}`, {
      name: input.name.trim(),
      sort_order: input.sortOrder,
      is_active: input.isActive,
    });
    return;
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminService[]>(
      token,
      "GET",
      `/v1/admin/services${buildQuery({ category_id: categoryId })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_list_services", {
    p_category_id: categoryId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AdminService[];
}

export async function createService(input: CreateServiceInput) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "POST", "/v1/admin/services", {
      category_id: input.categoryId,
      name: input.name.trim(),
      min_price: input.minPrice,
      max_price: input.maxPrice,
    });
    return;
  }

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
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", `/v1/admin/services/${input.serviceId}`, {
      category_id: input.categoryId,
      name: input.name.trim(),
      min_price: input.minPrice,
      max_price: input.maxPrice,
      is_active: input.isActive,
    });
    return;
  }

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

// ---------------------------------------------------------------------------
// Platform settings, commission and revenue
// ---------------------------------------------------------------------------

export type CategoryCommission = {
  id: number;
  name: string;
  commission_rate: number | null;
};

export type AdminSettings = {
  default_commission_rate: number;
  min_order_price: number;
  updated_at: string | null;
  categories: CategoryCommission[];
};

export type RevenueStats = {
  completed_count: number;
  total_gross: number;
  total_commission: number;
  total_net: number;
  avg_order: number;
  is_filtered: boolean;
};

export type RevenueByCategory = {
  category_id: number | null;
  category_name: string;
  completed_count: number;
  total_gross: number;
  total_commission: number;
  total_net: number;
};

export type RevenueDailyPoint = {
  day: string;
  total_gross: number;
  total_commission: number;
  total_net: number;
};

export type WorkerPayout = {
  worker_id: string;
  worker_name: string;
  worker_phone: string;
  jobs_count: number;
  total_gross: number;
  total_commission: number;
  total_net: number;
};

export async function loadSettings() {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<AdminSettings>(token, "GET", "/v1/admin/settings");
  }

  const { data, error } = await supabase.rpc("admin_get_settings");
  if (error) {
    throw new Error(error.message);
  }

  return (data ?? {
    default_commission_rate: 0.1,
    min_order_price: 0,
    updated_at: null,
    categories: [],
  }) as AdminSettings;
}

export async function updateSettings(input: {
  defaultCommissionRate: number;
  minOrderPrice: number;
}) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(token, "PATCH", "/v1/admin/settings", {
      default_commission_rate: input.defaultCommissionRate,
      min_order_price: input.minOrderPrice,
    });
    return;
  }

  const { error } = await supabase.rpc("admin_update_settings", {
    p_default_commission_rate: input.defaultCommissionRate,
    p_min_order_price: input.minOrderPrice,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function updateCategoryCommission(
  categoryId: number,
  commissionRate: number | null,
) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    await handyApiRequest(
      token,
      "PATCH",
      `/v1/admin/categories/${categoryId}/commission`,
      { commission_rate: commissionRate },
    );
    return;
  }

  const { error } = await supabase.rpc("admin_update_category_commission", {
    p_category_id: categoryId,
    p_commission_rate: commissionRate,
  });

  if (error) {
    throw new Error(error.message);
  }
}

export async function loadRevenueStats(dateRange: OverviewDateRange) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<RevenueStats>(
      token,
      "GET",
      `/v1/admin/revenue/stats${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
      })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_revenue_stats", {
    p_from: dateRange.from,
    p_to: dateRange.to,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? {
    completed_count: 0,
    total_gross: 0,
    total_commission: 0,
    total_net: 0,
    avg_order: 0,
    is_filtered: false,
  }) as RevenueStats;
}

export async function loadRevenueByCategory(dateRange: OverviewDateRange) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<RevenueByCategory[]>(
      token,
      "GET",
      `/v1/admin/revenue/by-category${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
      })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_revenue_by_category", {
    p_from: dateRange.from,
    p_to: dateRange.to,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as RevenueByCategory[];
}

export async function loadRevenueDaily(dateRange: OverviewDateRange) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<RevenueDailyPoint[]>(
      token,
      "GET",
      `/v1/admin/revenue/daily${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
      })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_revenue_daily", {
    p_from: dateRange.from,
    p_to: dateRange.to,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as RevenueDailyPoint[];
}

export async function loadWorkerPayouts(
  dateRange: OverviewDateRange,
  limit = 50,
) {
  if (isHandyApiConfigured) {
    const token = await getAccessToken();
    return handyApiRequest<WorkerPayout[]>(
      token,
      "GET",
      `/v1/admin/payouts${buildQuery({
        from: dateRange.from,
        to: dateRange.to,
        limit,
      })}`,
    );
  }

  const { data, error } = await supabase.rpc("admin_list_worker_payouts", {
    p_from: dateRange.from,
    p_to: dateRange.to,
    p_limit: limit,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as WorkerPayout[];
}
