IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'ExecutaJobOra2SP1')
	DROP PROCEDURE ExecutaJobOra2SP1
GO

CREATE PROCEDURE ExecutaJobOra2SP1
AS
declare @dataAzi datetime=getdate()

	/*PAS suplimentar: daca exista alte lucruri specifice ce trebuie executate de JOB se pot prevedea in SP */
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'corectiiDocument')
		exec corectiiDocumentSP null,null,null,null,@dataAzi