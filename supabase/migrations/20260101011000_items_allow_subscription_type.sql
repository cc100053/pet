alter table items
  drop constraint if exists items_type;

alter table items
  add constraint items_type check (
    type in ('cosmetic', 'consumable', 'subscription')
  );
