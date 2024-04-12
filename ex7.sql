USE PROJETS
	GO
	ALTER TABLE EMPLOYE
	ADD EMAIL VARCHAR(100)
	SELECT * FROM EMPLOYE
	INSERT INTO EMPLOYE 
		(NAS,
		 NOM,
		 PRENOM,
		 FONCTION,
		 SEXE,
		 DATE_EMBAUCHE,
		 EMAIL
		 )
	VALUES
		(123332632,
		'aa',
		'bb',
		'aaa@email.com',
		'M',
		'1999-01-01',
		'TEST')
GO
/*
Question 1 � Fonction pour g�n�rer les adresses courriels
�crire en T-SQL une fonction qui g�n�re l'adresse courriel d'un nouvel employ�. L�adresse de courriel a
la forme suivante : prenom.nom@entreprise-abc.qc.ca.
Exemple: FN_GENERER_EMAIL(�Alex�,�Drolet�)

*/
CREATE OR ALTER FUNCTION CREATION_EMAIL(@nom VARCHAR(10), @prenom VARCHAR(10)) RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @email VARCHAR(100)
    DECLARE @duplicates SMALLINT
    
    SET @duplicates = (SELECT COUNT(EMPLOYE.EMAIL) FROM EMPLOYE WHERE PRENOM = @prenom AND NOM = @nom)
    
  IF(@duplicates > 0)
    BEGIN
        SET @duplicates += 1
        SET @email = @prenom + @nom + CAST(@duplicates AS varchar(10)) + '@' + 'entreprise-abc.qc.ca'
    END
       ELSE
       BEGIN
       SET @email = @prenom + @nom + '@' + 'entreprise-abc.qc.ca'
    END
    
    RETURN @email
END
GO
PRINT dbo.CREATION_EMAIL('aa','bb')
/*
bbaa2@entreprise-abc.qc.ca

Completion time: 2024-04-12T11:21:15.3622656-04:00
*/
GO
/*
Question 2 � Proc�dure pour une cr�ation en lot des courriels des employ�s
�crire en T-SQL une proc�dure qui utilise un curseur pour parcourir les employ�s de l�entreprise et
peupler le champ COURRIEL � l�aide de la fonction cr��e au point pr�c�dent si celui-ci n�est pas
renseign�. 
*/
CREATE OR ALTER PROCEDURE CREATE_EMAILS_LOT
AS
BEGIN
	DECLARE cur_employes CURSOR FOR
		SELECT NOM,PRENOM, EMAIL
		FROM   EMPLOYE


	DECLARE @nom	VARCHAR(30)
	DECLARE @prenom VARCHAR(30)
	DECLARE @email VARCHAR(30)

	OPEN cur_employes
	FETCH NEXT FROM cur_employes INTO @nom, @prenom, @email
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF( @email IS NULL)
		BEGIN
			UPDATE EMPLOYE
			SET    EMAIL = dbo.CREATION_EMAIL(@nom,@prenom)
			WHERE CURRENT OF cur_employes
		END
		FETCH NEXT FROM cur_employes INTO @nom, @prenom, @email
	END
	CLOSE cur_employes
	DEALLOCATE cur_employes
END
GO

BEGIN TRANSACTION

SELECT NOM,PRENOM,EMAIL FROM EMPLOYE
EXECUTE dbo.CREATE_EMAILS_LOT
SELECT NOM,PRENOM,EMAIL FROM EMPLOYE

ROLLBACK
/*

avant:

NOM        PRENOM     EMAIL
---------- ---------- ------
Ban        Ray        NULL
Lacroix    Etienne    NULL
Gagnon     Eric       NULL
Gates      Bill       NULL
Monjal     Sylvie     NULL
Nadeau     Michel     NULL
Gagnon     Carmen     NULL
Gagnon     Martine    NULL
VanHoute   Eloi       NULL
Souci      Marcel     NULL
Souci      Marcel     NULL
Abott      Gino       NULL
Hey        Heidi      NULL
Colin      Maillard   NULL
Halou      Jean       NULL
Bazoo      Marc       NULL
Zouzou     Corinne    NULL
Bazoo      Marc       TEST
aa         bb         TEST

apr�s:

NOM        PRENOM     EMAIL
---------- ---------- -------------------------------------------
Blow       Jow        JowBlow@entreprise-abc.qc.ca
Ban        Ray        RayBan@entreprise-abc.qc.ca
Lacroix    Etienne    EtienneLacroix@entreprise-abc.qc.ca
Gagnon     Eric       EricGagnon@entreprise-abc.qc.ca
Gates      Bill       BillGates@entreprise-abc.qc.ca
Monjal     Sylvie     SylvieMonjal@entreprise-abc.qc.ca
Nadeau     Michel     MichelNadeau@entreprise-abc.qc.ca
Gagnon     Carmen     CarmenGagnon@entreprise-abc.qc.ca
Gagnon     Martine    MartineGagnon@entreprise-abc.qc.ca
VanHoute   Eloi       EloiVanHoute@entreprise-abc.qc.ca
Souci      Marcel     MarcelSouci@entreprise-abc.qc.ca
Souci      Marcel     MarcelSouci2@entreprise-abc.qc.ca
Abott      Gino       GinoAbott@entreprise-abc.qc.ca
Hey        Heidi      HeidiHey@entreprise-abc.qc.ca
Colin      Maillard   MaillardColin@entreprise-abc.qc.ca
Halou      Jean       JeanHalou@entreprise-abc.qc.ca
Bazoo      Marc       MarcBazoo2@entreprise-abc.qc.ca
Zouzou     Corinne    CorinneZouzou@entreprise-abc.qc.ca
Bazoo      Marc       TEST
aa         bb         TEST

*/

/*
Question 3 � Trigger pour un audit sur la modification du salaire d�un employ�
Cr�er une table AUDIT_EMPLOYE_SALAIRE qui va contenir de l�information sur chaque modification
apport�e au salaire d�employ�. On indiquera : le num�ro, le nom et le pr�nom de l�employ�, la date de
modification du salaire, l�ancien salaire, le nouveau salaire, et l�utilisateur qui a fait la modification.
�crire en T-SQL un trigger qui enregistre dans la table AUDIT_EMPLOYE_SALAIRE toutes les
modifications apport�es aux salaires des employ�s.
*/

/*
Q3.A Dans un premier temps, pour simplifier, consid�rez que seulement le salaire d�1 employ�
peut �tre modifi� dans la m�me transaction.
*/

--Cr�ation table
DROP TABLE IF EXISTS AUDIT_EMPLOYE_SALAIRE

CREATE TABLE AUDIT_EMPLOYE_SALAIRE(
	NO_EMPLOYE					SMALLINT		NOT NULL,
	NOM							VARCHAR(30)		NOT NULL,
	PRENOM						VARCHAR(30)		NOT NULL,
	DATE_MODIFICATION_SALAIRE	DATE			NOT NULL,
	ANCIEN_SALAIRE				DECIMAL(7,0)	NOT NULL,
	NOUVEAU_SALAIRE				DECIMAL(7,0)	NOT NULL,
	UTILISATEUR					VARCHAR(50)		NOT NULL

)

--Creation Trigger 
/*
Q3.A Dans un premier temps, pour simplifier, consid�rez que seulement le salaire d�1 employ�
peut �tre modifi� dans la m�me transaction.
*/
DROP TRIGGER IF EXISTS TRIGGER_CHANGEMENT_SALAIRE
GO
CREATE TRIGGER TRIGGER_CHANGEMENT_SALAIRE
ON EMPLOYE

AFTER UPDATE
AS
	IF UPDATE(SALAIRE)
	BEGIN
		INSERT INTO AUDIT_EMPLOYE_SALAIRE
			(NO_EMPLOYE,
			NOM,
			PRENOM,
			DATE_MODIFICATION_SALAIRE,
			ANCIEN_SALAIRE,
			NOUVEAU_SALAIRE,
			UTILISATEUR)
		VALUES
			((SELECT NO_EMPLOYE FROM deleted),
			(SELECT NOM FROM deleted),
			(SELECT PRENOM FROM deleted),
			GETDATE(),
			(SELECT SALAIRE FROM deleted),
			(SELECT SALAIRE FROM inserted),
			SUSER_SNAME())
	END

BEGIN TRANSACTION
UPDATE EMPLOYE
	SET SALAIRE = 1000
	WHERE NO_EMPLOYE = 1
SELECT * FROM AUDIT_EMPLOYE_SALAIRE
ROLLBACK

/*
NO_EMPLOYE NOM                            PRENOM                         DATE_MODIFICATION_SALAIRE ANCIEN_SALAIRE                          NOUVEAU_SALAIRE                         UTILISATEUR
---------- ------------------------------ ------------------------------ ------------------------- --------------------------------------- --------------------------------------- --------------------------------------------------
1          Blow                           Jow                            2024-04-12                122000                                  1000                                    DESKTOP-RSKQ5V3\xavto
*/


--Cr�ation Trigger
/*
Q.3B	Dans un deuxi�me temps, r��crivez la proc�dure en consid�rant que le salaire de plusieurs
		employ�s peuvent �tre modifi�s dans la m�me transaction et d�clencher le trigger.
*/
DROP TRIGGER IF EXISTS TRIGGER_CHANGEMENT_SALAIRE
GO
CREATE TRIGGER TRIGGER_CHANGEMENT_SALAIRE
ON EMPLOYE
AFTER UPDATE
AS
BEGIN
    IF UPDATE(SALAIRE)
    BEGIN
        INSERT INTO AUDIT_EMPLOYE_SALAIRE
            (NO_EMPLOYE,
            NOM,
            PRENOM,
            DATE_MODIFICATION_SALAIRE,
            ANCIEN_SALAIRE,
            NOUVEAU_SALAIRE,
            UTILISATEUR)
        SELECT 
            deleted.NO_EMPLOYE,
            deleted.NOM,
            deleted.PRENOM,
            GETDATE(),
            deleted.SALAIRE,
            inserted.SALAIRE,
            SUSER_SNAME()
        FROM 
            deleted
        INNER JOIN 
            inserted ON deleted.NO_EMPLOYE = inserted.NO_EMPLOYE;
    END
END

BEGIN TRANSACTION
	UPDATE EMPLOYE
		SET SALAIRE = 4000
		WHERE NO_EMPLOYE IN(5,6,8,9,10)
	SELECT * FROM AUDIT_EMPLOYE_SALAIRE
ROLLBACK
/*
NO_EMPLOYE NOM                            PRENOM                         DATE_MODIFICATION_SALAIRE ANCIEN_SALAIRE                          NOUVEAU_SALAIRE                         UTILISATEUR
---------- ------------------------------ ------------------------------ ------------------------- --------------------------------------- --------------------------------------- --------------------------------------------------
10         VanHoute                       Eloi                           2024-04-12                28000                                   4000                                    TECNISTICO\Tecnistico
9          Gagnon                         Martine                        2024-04-12                38000                                   4000                                    TECNISTICO\Tecnistico
8          Gagnon                         Carmen                         2024-04-12                42000                                   4000                                    TECNISTICO\Tecnistico
6          Monjal                         Sylvie                         2024-04-12                45000                                   4000                                    TECNISTICO\Tecnistico
5          Gates                          Bill                           2024-04-12                78000                                   4000                                    TECNISTICO\Tecnistico

(5 rows affected)
*/

	