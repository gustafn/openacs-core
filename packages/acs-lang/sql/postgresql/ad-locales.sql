--
-- packages/language/sql/language-create.sql
--
-- @author Jeff Davis (davis@xarg.net)
-- @creation-date 2000-09-10
-- @cvs-id $Id$
--

-- ****************************************************************************
-- * The lang_messages table holds the message catalog.
-- * It is populated by ad_lang_message_register.
-- * The registered_p flag denotes that a message exists in a file
-- * that gets loaded on server startup, and hence should not get updated.
-- ****************************************************************************

begin;

create table ad_locales (
  locale		varchar(30)
                        constraint ad_locale_abbrev_pk
                        primary key,
  language		char(3) 
                        constraint ad_language_name_nil
			not null,
  country		char(2) 
                        constraint ad_country_name_nil
			not null,
  variant		varchar(30),
  label			varchar(200)
                        constraint ad_locale_name_nil
			not null
                        constraint ad_locale_name_unq
                        unique,
  nls_language		varchar(30)
                        constraint ad_locale_nls_lang_nil
			not null,
  nls_territory		varchar(30),
  nls_charset		varchar(30),
  mime_charset		varchar(30),
  -- is this the default locale for its language
  default_p             boolean default 'f',
  -- Determines which locales a user can choose from for the UI
  enabled_p             boolean default 't'
);

comment on table ad_locales is '
  An OpenACS locale is identified by a language and country.
  Locale definitions in Oracle consist of a language, and optionally
  territory and character set.  (Languages are associated with default
  territories and character sets when not defined).  The formats
  for numbers, currency, dates, etc. are determined by the territory.
  language is two letter abbrev is ISO 639 language code
  country is two letter abbrev is ISO 3166 country code
  mime_charset is IANA charset name
  nls_charset is  Oracle charset name
';

create view enabled_locales as
select * from ad_locales
where enabled_p = 't';

create table ad_locale_user_prefs (
  user_id               integer
                        constraint ad_locale_user_prefs_users_fk
                        references users (user_id) on delete cascade,
  package_id            integer
                        constraint lang_package_l_u_package_id_fk
                        references apm_packages(package_id) on delete cascade,
  locale                varchar(30) not null
                        constraint trb_language_preference_lid_fk
                        references ad_locales (locale) on delete cascade
);

--
--
-- And now for some default locales
--
--

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
  values ('en_US', 'English (US)', 'en', 'US', 'AMERICAN', 
          'AMERICA', 'WE8ISO8859P1', 'ISO-8859-1', 't', 't');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
  values ('en_GB', 'English (GB)', 'en', 'GB', 'ENGLISH', 
          'GREAT BRITAIN', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('de_DE', 'German (DE)', 'de', 'DE', 'GERMAN', 
         'GERMANY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('es_ES', 'Spanish (ES)', 'es', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('ast_ES', 'Asturian (ES)', 'ast', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p) 
values ('gl_ES', 'Galician-Portugese (ES)', 'gl', 'ES', 'SPANISH', 
       'SPAIN', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fr_FR', 'French (FR)', 'fr', 'FR', 'FRENCH', 
        'FRANCE', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ja_JP', 'Japanese (JP)', 'ja', 'JP', 'JAPANESE', 
        'JAPAN', 'JA16SJIS', 'Shift_JIS', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('da_DK', 'Danish (DK)', 'da', 'DK', 'DANISH', 'DENMARK', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('sv_SE', 'Swedish (SE)', 'sv', 'SE', 'SWEDISH', 'SWEDEN', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('fi_FI', 'Finnish (FI)', 'fi', 'FI', 'FINNISH', 'FINLAND', 'WE8ISO8859P15', 'ISO-8859-15', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('nl_NL', 'Dutch (NL)', 'nl', 'NL', 'DUTCH', 'THE NETHERLANDS', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ch_zh', 'Chinese (ZH)', 'CH', 'ZH', 'SIMPLIFIED CHINESE', 'CHINA', 'ZHT32EUC', 'ISO-2022-CN', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pl_PL', 'Polish (PL)', 'pl', 'PL', 'POLISH', 'POLAND', 'EE8ISO8859P2', 'ISO-8859-2', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('no_NO', 'Norwegian  (NO)', 'no', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('tl_PH', 'Tagalog (PH)', 'tl', 'PH', 'TAGALOG', 'PHILIPPINES', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('el_GR', 'Greek (GR)', 'el', 'GR', 'GREEK', 'GREECE', 'EL8ISO8859P7', 'ISO-8859-7', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('it_IT', 'Italian (IT)', 'it', 'IT', 'ITALIAN', 'ITALY', 'WE8DEC', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ru_RU', 'Russian (RU)', 'ru', 'RU', 'RUSSIAN', 'CIS', 'RU8PC855', 'windows-1251', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('si_LK', 'Sinhalese (LK)','si', 'LK', 'ENGLISH', 'UNITED KINGDOM', 'UTF8', 'ISO-10646-UTF-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('sh_HR', 'Serbo-Croatian (SR/HR)', 'sr', 'YU', 'SLOVENIAN', 'SLOVENIA', 'YUG7ASCII', 'ISO-8859-5', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('nn_NO', 'Norwegian (NN)','nn', 'NO', 'NORWEGIAN', 'NORWAY', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pt_BR', 'Portuguese (BR)', 'pt', 'BR', 'BRAZILIAN PORTUGUESE', 'BRAZIL', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('pt_PT', 'Portuguese (PT)', 'pt', 'PT', 'PORTUGUESE', 'PORTUGAL', 'WE8ISO8859P1', 'ISO-8859-1', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('TH_TH', 'Thai (TH)', 'th', 'TH', 'THAI', 'THAILAND', 'TH8TISASCII', 'TIS-620', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('AR_EG', 'Arabic (AR_EG)', 'AR ', 'EG', 'ARABIC', 'EGYPT', 'AR8ISO8859P6', 'ISO-8859-6', 'f', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('AR_LB', 'Arabic (AR_LB)', 'AR ', 'LB', 'ARABIC', 'LEBANON', 'AR8ISO8859P6', 'ISO-8859-6', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('tr_TR', 'Turkish (TR)', 'tr ', 'TR', 'TURKISH', 'TURKEY', 'WE8ISO8859P9', 'ISO-8859-9', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ms_my', 'Malaysia (MY)', 'ms ', 'MY', 'MALAY', 'MALAYSIA', 'US7ASCII', 'US-ASCII', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hi_IN', 'Hindi (IN)', 'hi ', 'IN', 'HINDI', 'INDIA', 'UTF8', 'UTF-8', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('ko_KR', 'Korean(KOR)', 'ko ', 'KR', 'KOREAN', 'KOREA', 'KO16KSC5601', 'EUC-KR', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('zh_TW', 'Chinese (TW)', 'zh ', 'TW', 'TRADITIONAL CHINESE', 'TAIWAN', 'ZHT16BIG5', 'Big5', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('hu_HU', 'Hungarian (HU)', 'hu ', 'HU', 'HUNGARIAN', 'HUNGARY', 'EE8ISO8859P2', 'ISO-8859-2', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('FA_IR', 'Farsi', 'FA ', 'IR', 'AMERICAN', 'ALGERIAN', 'AL24UTFFSS', 'windows-1256', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('RO_RO', 'Romainian', 'RO ', 'RO', 'ROMAINIAN', 'ROMAINIA', 'EE8ISO8859P2', 'UTF-8', 't', 'f');

insert into ad_locales 
       (locale, label, language, country, nls_language, nls_territory, 
        nls_charset, mime_charset, default_p, enabled_p)
 values ('HR_HR', 'Croatian', 'HR', 'HR', 'CROATIAN', 'CROATIA','UTF8','UTF-8','t','f');

end;
