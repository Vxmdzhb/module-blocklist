-- Blocklist: the module's page and its navbar link.
--
-- Runs once (it is a migration), after core's navbar layout, so the link
-- lands straight in the right pin. `tools/module.php purge blocklist` forgets it,
-- so the next `tools/install.php --schema-only` puts everything back.
-- Its link goes in the admin panel's main menu.

INSERT IGNORE INTO `page` (url_id, i18n, file_name, template, controller, hidden, comments)
VALUES ('WORDING_ADMIN_BLOCKLIST', 1, 'admin_blocklist', 1, 1, 0, 0);

UPDATE `page` SET `module` = 'blocklist'
 WHERE `module` = '' AND `file_name` = 'admin_blocklist';

INSERT IGNORE INTO `page_closure` (ancestor, descendant)
SELECT id, id FROM `page` WHERE url_id = 'WORDING_ADMIN_BLOCKLIST';
INSERT IGNORE INTO `page_closure` (ancestor, descendant)
SELECT a.id, d.id FROM `page` a, `page` d
 WHERE a.url_id = 'WORDING_ADMIN' AND d.url_id = 'WORDING_ADMIN_BLOCKLIST';

INSERT IGNORE INTO `page_meta` (page_id, title, description)
SELECT id, '', '' FROM `page` WHERE url_id = 'WORDING_ADMIN_BLOCKLIST';

INSERT IGNORE INTO `page_robots` (page_id, `index`, follow)
SELECT id, 0, 0 FROM `page` WHERE url_id = 'WORDING_ADMIN_BLOCKLIST';

-- ── Navbar link ──────────────────────────────────────────────────────────────
SET @blocklist_page := (SELECT id FROM `page` WHERE url_id = 'WORDING_ADMIN_BLOCKLIST' LIMIT 1);
SET @blocklist_navbar := (SELECT id FROM `navbar` WHERE name = 'admin' LIMIT 1);
-- The main menu: the pin holding Users, else the alphabetical pin, else the
-- last pin (the rule migrate_zzz_admin_nav_pin_fix.sql uses).
SET @blocklist_pin := COALESCE(
    (SELECT e.pin_id FROM `navbar_entry` e
       JOIN `navbar_pin` np ON np.id = e.pin_id
      WHERE np.navbar_id = @blocklist_navbar AND e.name = 'WORDING_ADMIN_USERS' LIMIT 1),
    (SELECT id FROM `navbar_pin` WHERE navbar_id = @blocklist_navbar AND sort_mode = 0 ORDER BY sort_order ASC, id ASC LIMIT 1),
    (SELECT id FROM `navbar_pin` WHERE navbar_id = @blocklist_navbar ORDER BY sort_order DESC, id DESC LIMIT 1)
);
SET @blocklist_existing := (
    SELECT ni.id FROM `navbar_internal` ni
      JOIN `navbar_entry` e  ON e.id = ni.id
      JOIN `navbar_pin`   np ON np.id = e.pin_id
     WHERE ni.page_id = @blocklist_page AND np.navbar_id = @blocklist_navbar LIMIT 1
);
INSERT INTO `navbar_entry_ids` (id)
SELECT NULL WHERE @blocklist_page IS NOT NULL AND @blocklist_pin IS NOT NULL AND @blocklist_existing IS NULL;
SET @blocklist_nav := COALESCE(@blocklist_existing, LAST_INSERT_ID());
INSERT IGNORE INTO `navbar_entry` (id, pin_id, internal, name, i18n, active, sort_order)
SELECT @blocklist_nav, @blocklist_pin, 1, 'WORDING_ADMIN_BLOCKLIST', 1, 1, 0
 WHERE @blocklist_page IS NOT NULL AND @blocklist_pin IS NOT NULL AND @blocklist_nav IS NOT NULL;
INSERT IGNORE INTO `navbar_internal` (id, page_id)
SELECT @blocklist_nav, @blocklist_page
 WHERE @blocklist_page IS NOT NULL AND @blocklist_nav IS NOT NULL;
