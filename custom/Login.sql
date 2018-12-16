DELIMITER $$

-- -----------------------------------------------
DROP FUNCTION IF EXISTS App_User_Confirm_Creds $$
CREATE FUNCTION App_User_Confirm_Creds(email VARCHAR(128),
                                       pword VARCHAR(40))
RETURNS BOOLEAN
BEGIN
   DECLARE user_id INT UNSIGNED;
   DECLARE user_hash BINARY(16);
   DECLARE user_salt CHAR(32);

-- Get user's login values:
   SELECT u.id,
          u.pw_hash,
          s.salt
     INTO user_id,
          user_hash,
          user_salt
     FROM User u
          INNER JOIN Salt s ON u.id = s.id_user
    WHERE u.email = email;

   RETURN ssys_confirm_salted_hash(user_hash, user_salt, pword);
END $$

-- ---------------------------------------
DROP PROCEDURE IF EXISTS App_User_Login $$
CREATE PROCEDURE App_User_Login(email VARCHAR(128), pword VARCHAR(40))
BEGIN
   -- Early termination if not in a valid session:
   IF NOT(ssys_current_session_is_valid()) THEN
      SELECT 1 AS error, 'Expired Session' AS msg;
   ELSEIF NOT(App_User_Confirm_Creds(email, pword)) THEN
      CALL App_Session_Abandon(@session_confirmed_id);
      SELECT 1 AS error, 'Invalid credentials' AS msg;
   ELSE
      -- Good session and credentials, setup Session_Info:
      UPDATE Session_Info i
             INNER JOIN (SELECT @session_confirmed_id AS id_session,
                                u.id,
                                u.email
                           FROM User u
                          WHERE u.email = email) AS a ON a.id_session = i.id_session
         SET i.user_id = a.id,
             i.user_email = a.email
       WHERE i.id_session = @session_confirmed_id;

       SELECT 0 AS error, 'Successful Login' AS msg;
   END IF;
END $$

-- --------------------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Create $$
CREATE PROCEDURE App_User_Create(email VARCHAR(128),
                                 name VARCHAR(80),
                                 pword1 VARCHAR(40),
                                 pword2 VARCHAR(40))
proc_block: BEGIN
   DECLARE newid INT UNSIGNED;
   DECLARE ecount INT UNSIGNED;
   DECLARE rcount INT UNSIGNED;

   -- First check early-termination conditions of mismatched
   -- passwords and missing dropped_salt:

   IF STRCMP(pword1, pword2) THEN
      -- Query to populate the standard form-result variables
      SELECT 1 AS error, 'Mismatched Passwords' AS msg;
      LEAVE proc_block;
   END IF;

   IF @dropped_salt IS NULL THEN
      -- Fatal error, use non-recoverable termination
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Missing drop-salt instruction.';
   END IF;

   -- Application-specific code:

   -- Early termination with message if email already in system:
   SELECT COUNT(*) INTO ecount
     FROM User u
    WHERE u.email = email;

   IF ecount > 0 THEN
      -- Query to populate the standard form-result variables
      SELECT 1 AS error, CONCAT('Email ''', email, ''' already in use.') AS msg;
      LEAVE proc_block;
   END IF;

   START TRANSACTION;

   -- If we get here, we have unique email name and matched passwords.
   -- Create user record and linked salt record:
   INSERT INTO User (email,
                     name,
                     pw_hash)
             VALUES (email,
                     name,
                     ssys_hash_password_with_salt(pword1, @dropped_salt));

   IF ROW_COUNT() > 0 THEN
      SET newid = LAST_INSERT_ID();
      INSERT INTO Salt (id_user, salt)
           VALUES (newid, @dropped_salt);

      -- Save ROW_COUNT() so commit doesn't change it.(?)
      -- Otherwise, ROW_COUNT() is never > 0.
      SET rcount = ROW_COUNT();

      COMMIT;

      IF rcount > 0 THEN
         CALL App_User_Login(email, pword1);
         SELECT 0 AS error, 'Success' AS msg;

         SELECT email, pword1;

         LEAVE proc_block;
      END IF;
   ELSE
      ROLLBACK;
   END IF;

   SELECT 1 AS error,
          CONCAT('Failed to create new user account for ''', email, '''.') AS msg;
END $$

-- This procedure is called for a TRUE/FALSE value.  0 = false, !0 = true
DROP PROCEDURE IF EXISTS App_Session_Validate $$
CREATE PROCEDURE App_Session_Validate(session_id INT UNSIGNED)
BEGIN
   DECLARE sess_name VARCHAR(80);
   DECLARE sess_account INT UNSIGNED;

   SELECT i.id_account, i.name_account INTO sess_account, sess_name
     FROM Session_Info i
          INNER JOIN SSYS_SESSION s ON i.id_session = s.id
    WHERE i.is_session = session_id
      AND s.expires > NOW();

   IF sess_account IS NOT NULL THEN
      SET @session_confirmed_account = sess_account,
          @session_account_name = sess_name;
      SELECT 1;
   ELSE
      SELECT 0;
   END IF;
END $$


DELIMITER ;
