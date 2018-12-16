SET default_storage_engine=InnoDB;

-- Authorized User Section (two tables)
CREATE TABLE IF NOT EXISTS User
(
   id      INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   pw_hash BINARY(16),
   email   VARCHAR(128),
   name    VARCHAR(80),

   UNIQUE KEY(email)
);

CREATE TABLE IF NOT EXISTS Salt
(
   id_user INT UNSIGNED NOT NULL PRIMARY KEY,
   salt    CHAR(32)
);

-- Session Information Section (one table)
CREATE TABLE IF NOT EXISTS Session_Info
(
   id_session INT UNSIGNED UNIQUE KEY,

   user_id             INT UNSIGNED,
   user_email          VARCHAR(128),

   INDEX(id_session)
);


