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
