
CREATE PROCEDURE wDateFirma_tabela
as
	if object_id('tempdb..#datefirma') is null 
		create table #datefirma(locm varchar(50))
alter table #datefirma add locm_proprietate varchar(50) default null,
			codFiscal varchar(50) default null, firma varchar(200) default null, ordreg varchar(50) default null, judet varchar(100) default null, sediu varchar(150) default null,
			adresa varchar(300) default null, cont varchar(50) default null, banca varchar(100) default null, capitalSocial varchar(50) default null, telfax varchar(100) default null
