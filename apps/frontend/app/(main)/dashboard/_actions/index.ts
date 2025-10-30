"use server";

import { revalidateTag } from "next/cache";

export async function applyFilter(filterId: string) {
  // 呼び出し側からの filterId を受け取り、Server Action で状態を反映する例
  await new Promise((resolve) => setTimeout(resolve, 100));
  revalidateTag("dashboard");
}
