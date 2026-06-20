import { supabase } from "@/lib/supabase";

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
