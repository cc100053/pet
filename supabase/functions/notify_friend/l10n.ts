// Push-notification localization for notify_friend (locale templates and
// store-item display names). Kept separate from the orchestration in
// index.ts. These strings are push-only and intentionally distinct from the
// in-app `lib/l10n` ARB strings.

function nonEmptyOrNull(value: string | null | undefined): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

type L10nStrings = {
  defaultTextBody: string;
  defaultPetName: string;
  defaultSenderName: string;
  feedBodyTemplate: string;
  hungerReminderTemplate: string;
  hungerUrgentTemplate: string;
  storePurchaseTemplate: string;
};

const l10n: Record<string, L10nStrings> = {
  en: {
    defaultTextBody: "New message",
    defaultPetName: "Pet",
    defaultSenderName: "Someone",
    feedBodyTemplate: "{sender} fed {pet}",
    hungerReminderTemplate: "{pet} is getting hungry. Time to feed!",
    hungerUrgentTemplate: "{pet} is very hungry! Please feed now!",
    storePurchaseTemplate: "{sender} bought {item} for {pet}",
  },
  ja: {
    defaultTextBody: "新しいメッセージ",
    defaultPetName: "ペット",
    defaultSenderName: "だれか",
    feedBodyTemplate: "{sender}さんが{pet}にごはんをあげました",
    hungerReminderTemplate:
      "{pet}がお腹を空かせています。ごはんをあげてください！",
    hungerUrgentTemplate: "{pet}がとてもお腹を空かせています！今すぐごはんを！",
    storePurchaseTemplate: "{sender}が{pet}に{item}を買いました",
  },
  ko: {
    defaultTextBody: "새 메시지",
    defaultPetName: "펫",
    defaultSenderName: "누군가",
    feedBodyTemplate: "{sender}님이 {pet}에게 밥을 줬어요",
    hungerReminderTemplate: "{pet}가 배고파하고 있어요. 먹이를 주세요!",
    hungerUrgentTemplate: "{pet}가 매우 배고파요! 지금 바로 먹이를 주세요!",
    storePurchaseTemplate: "{sender}님이 {pet}에게 {item}을 사줬어요",
  },
  zh: {
    defaultTextBody: "新消息",
    defaultPetName: "宠物",
    defaultSenderName: "某人",
    feedBodyTemplate: "{sender} 喂了 {pet}",
    hungerReminderTemplate: "{pet}有点饿了，记得喂食！",
    hungerUrgentTemplate: "{pet}非常饿！请立即喂食！",
    storePurchaseTemplate: "{sender}给{pet}买了{item}",
  },
  "zh-TW": {
    defaultTextBody: "新訊息",
    defaultPetName: "寵物",
    defaultSenderName: "某人",
    feedBodyTemplate: "{sender} 餵了 {pet}",
    hungerReminderTemplate: "{pet} 有點餓了，記得餵食！",
    hungerUrgentTemplate: "{pet} 非常餓！請立即餵食！",
    storePurchaseTemplate: "{sender}買了{item}給{pet}",
  },
};

const localizedStoreItemNames: Record<string, Record<string, string>> = {
  en: {
    background_default: "Default Background",
    background_test1: "Galaxy Background",
    background_sage_frame: "Sage Frame Background",
    background_lilac_frame: "Lilac Frame Background",
    background_bubble_sky: "Bubble Sky Background",
    background_starlit_dream: "Starlit Dream Background",
    furniture_emoji_sofa: "Sofa",
    furniture_emoji_plant: "Plant",
    furniture_emoji_frame: "Picture Frame",
    furniture_emoji_teddy: "Teddy Bear",
    furniture_emoji_brick: "Bricks",
    furniture_emoji_tv: "TV",
    furniture_emoji_bath: "Bath",
    furniture_emoji_ribbon: "Ribbon",
    equip_straw_hat: "Straw Hat",
    equip_crown: "Crown",
    equip_sunglasses: "Sunglasses",
    equip_ribbon: "Ribbon",
  },
  ja: {
    background_default: "デフォルト背景",
    background_test1: "銀河",
    background_sage_frame: "セージフレーム背景",
    background_lilac_frame: "ライラックフレーム背景",
    background_bubble_sky: "バブルスカイ背景",
    background_starlit_dream: "スターリットドリーム背景",
    furniture_emoji_sofa: "ソファ",
    furniture_emoji_plant: "観葉植物",
    furniture_emoji_frame: "フォトフレーム",
    furniture_emoji_teddy: "ぬいぐるみ",
    furniture_emoji_brick: "レンガ",
    furniture_emoji_tv: "テレビ",
    furniture_emoji_bath: "バス",
    furniture_emoji_ribbon: "リボン",
    equip_straw_hat: "麦わら帽子",
    equip_crown: "王冠",
    equip_sunglasses: "サングラス",
    equip_ribbon: "リボン",
  },
  ko: {
    background_default: "기본 배경",
    background_test1: "은하 배경",
    background_sage_frame: "세이지 프레임 배경",
    background_lilac_frame: "라일락 프레임 배경",
    background_bubble_sky: "버블 스카이 배경",
    background_starlit_dream: "별빛 드림 배경",
    furniture_emoji_sofa: "소파",
    furniture_emoji_plant: "식물",
    furniture_emoji_frame: "액자",
    furniture_emoji_teddy: "테디베어",
    furniture_emoji_brick: "벽돌",
    furniture_emoji_tv: "TV",
    furniture_emoji_bath: "욕조",
    furniture_emoji_ribbon: "리본",
    equip_straw_hat: "밀짚모자",
    equip_crown: "왕관",
    equip_sunglasses: "선글라스",
    equip_ribbon: "리본",
  },
  zh: {
    background_default: "默认背景",
    background_test1: "银河背景",
    background_sage_frame: "鼠尾草花边背景",
    background_lilac_frame: "丁香花边背景",
    background_bubble_sky: "泡泡天空背景",
    background_starlit_dream: "星梦背景",
    furniture_emoji_sofa: "沙发",
    furniture_emoji_plant: "盆栽",
    furniture_emoji_frame: "画框",
    furniture_emoji_teddy: "泰迪熊",
    furniture_emoji_brick: "积木墙",
    furniture_emoji_tv: "电视",
    furniture_emoji_bath: "浴缸",
    furniture_emoji_ribbon: "缎带",
    equip_straw_hat: "草帽",
    equip_crown: "皇冠",
    equip_sunglasses: "太阳眼镜",
    equip_ribbon: "缎带",
  },
  "zh-TW": {
    background_default: "預設背景",
    background_test1: "銀河背景",
    background_sage_frame: "鼠尾草花邊背景",
    background_lilac_frame: "丁香花邊背景",
    background_bubble_sky: "泡泡天空背景",
    background_starlit_dream: "星夢背景",
    furniture_emoji_sofa: "沙發",
    furniture_emoji_plant: "盆栽",
    furniture_emoji_frame: "畫框",
    furniture_emoji_teddy: "泰迪熊",
    furniture_emoji_brick: "積木牆",
    furniture_emoji_tv: "電視",
    furniture_emoji_bath: "浴缸",
    furniture_emoji_ribbon: "緞帶",
    equip_straw_hat: "草帽",
    equip_crown: "皇冠",
    equip_sunglasses: "太陽眼鏡",
    equip_ribbon: "緞帶",
  },
};

function normalizeLocale(locale: string | null | undefined): string {
  if (!locale) return "zh-TW";
  const trimmed = locale.trim();
  if (!trimmed) return "zh-TW";
  if (/^ja([_-].+)?$/i.test(trimmed)) return "ja";
  if (/^ko([_-].+)?$/i.test(trimmed)) return "ko";
  if (/^en([_-].+)?$/i.test(trimmed)) return "en";
  if (/^zh[-_](hant|tw|hk)([_-].+)?$/i.test(trimmed)) return "zh-TW";
  if (/^zh([_-].+)?$/i.test(trimmed)) return "zh";
  const lang = trimmed.split(/[-_]/)[0]?.toLowerCase();
  if (lang === "ja") return "ja";
  if (lang === "ko") return "ko";
  if (lang === "en") return "en";
  if (lang === "zh") return "zh";
  return "en";
}

export function localizedAppName(locale: string | null | undefined): string {
  return normalizeLocale(locale) === "ja" ? "ペットモ" : "PetTomo";
}

export function getL10n(locale: string | null | undefined): L10nStrings {
  const normalized = normalizeLocale(locale);
  return l10n[normalized] ?? l10n.en;
}

export function localizedStoreItemName(
  sku: string | null | undefined,
  locale: string | null | undefined,
): string {
  const normalized = normalizeLocale(locale);
  const fallbackSku = nonEmptyOrNull(sku) ?? "";
  if (!fallbackSku) {
    return "";
  }
  return localizedStoreItemNames[normalized]?.[fallbackSku] ??
    localizedStoreItemNames.en[fallbackSku] ??
    fallbackSku;
}
