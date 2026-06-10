// Pet type + push-notification avatar resolution for notify_friend.

export type PetType = "cat" | "fish" | "ghost" | "tiger";

export const PET_AVATAR_URL_BY_TYPE: Record<PetType, string> = {
  cat:
    "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/cat_stay.gif",
  fish:
    "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/fish_stay.gif",
  ghost:
    "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/ghost_stay.gif",
  // tiger intentionally reuses the ghost GIF: there is no published
  // `tiger_stay.gif` on R2 (verified 404), so pointing tiger at its own URL
  // would make the notification image fail to load. Restore the tiger URL only
  // once that asset is published.
  tiger:
    "https://pub-0c7a891a023a468a8ee757419f88af8d.r2.dev/pets/avatars/ghost_stay.gif",
};

export const PET_AVATAR_ASSET_BY_TYPE: Record<PetType, string> = {
  cat: "assets/pet/cat/cat_stay.gif",
  fish: "assets/pet/fish/fish_stay.gif",
  ghost: "assets/pet/ghost/ghost_stay.gif",
  tiger: "assets/pet/tiger/tiger_stay.gif",
};

export const DEFAULT_PET_TYPE: PetType = "ghost";
export const DEFAULT_PET_AVATAR_URL = PET_AVATAR_URL_BY_TYPE[DEFAULT_PET_TYPE];

export function normalizePetType(value: string | null | undefined): PetType {
  const normalized = value?.trim().toLowerCase();
  if (
    normalized === "cat" ||
    normalized === "fish" ||
    normalized === "ghost" ||
    normalized === "tiger"
  ) {
    return normalized;
  }
  return DEFAULT_PET_TYPE;
}

export function extractPetType(colorDna: unknown): PetType {
  if (!colorDna || typeof colorDna !== "object") {
    return DEFAULT_PET_TYPE;
  }
  const petTypeValue = (colorDna as Record<string, unknown>).pet_type;
  if (typeof petTypeValue !== "string") {
    return DEFAULT_PET_TYPE;
  }
  return normalizePetType(petTypeValue);
}
