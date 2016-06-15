CREATE TABLE [dbo].[nomencl] (
    [Cod]                    CHAR (20)    NOT NULL,
    [Tip]                    CHAR (1)     NOT NULL,
    [Denumire]               CHAR (150)   NOT NULL,
    [UM]                     CHAR (3)     NOT NULL,
    [UM_1]                   CHAR (3)     NOT NULL,
    [Coeficient_conversie_1] FLOAT (53)   NOT NULL,
    [UM_2]                   CHAR (20)    NOT NULL,
    [Coeficient_conversie_2] FLOAT (53)   NOT NULL,
    [Cont]                   VARCHAR (20) NULL,
    [Grupa]                  CHAR (13)    NOT NULL,
    [Valuta]                 CHAR (3)     NOT NULL,
    [Pret_in_valuta]         FLOAT (53)   NOT NULL,
    [Pret_stoc]              FLOAT (53)   NOT NULL,
    [Pret_vanzare]           FLOAT (53)   NOT NULL,
    [Pret_cu_amanuntul]      FLOAT (53)   NOT NULL,
    [Cota_TVA]               REAL         NOT NULL,
    [Stoc_limita]            FLOAT (53)   NOT NULL,
    [Stoc]                   FLOAT (53)   NOT NULL,
    [Greutate_specifica]     FLOAT (53)   NOT NULL,
    [Furnizor]               CHAR (13)    NOT NULL,
    [Loc_de_munca]           CHAR (150)   NOT NULL,
    [Gestiune]               CHAR (13)    NOT NULL,
    [Categorie]              SMALLINT     NOT NULL,
    [Tip_echipament]         CHAR (21)    NOT NULL,
    [detalii]                XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[nomencl]([Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip]
    ON [dbo].[nomencl]([Tip] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[nomencl]([Denumire] ASC);


GO
CREATE STATISTICS [_dta_stat_188787980_10_1]
    ON [dbo].[nomencl]([Grupa], [Cod]);


GO
--***
CREATE trigger nomenclsterg on nomencl for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssn
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Cod, Tip, Denumire, UM, UM_1, Coeficient_conversie_1, UM_2, Coeficient_conversie_2, Cont, Grupa, Valuta,
	Pret_in_valuta, Pret_stoc, Pret_vanzare, Pret_cu_amanuntul, Cota_TVA, Stoc_limita, Stoc, Greutate_specifica,
	Furnizor, Loc_de_munca, Gestiune, Categorie, Tip_echipament
   from deleted

GO

create trigger tr_validNomencl on nomencl for insert, update, delete not for replication as
begin try

	IF not EXISTS (select 1 from INSERTED i, grupe g where i.grupa=g.grupa) and isnull((select count(*) from inserted),0)>0 
		raiserror ('Articolul trebuie sa apartina unei grupe de articole!', 16, 1)

	IF EXISTS (select 1 from INSERTED where ISNULL(Cont,'')='')
		raiserror ('Articolul trebuie sa aiba setat un CONT contabil!', 16, 1)
			
	IF UPDATE (COD)
	BEGIN
		/** 
		Cazul stergerilor 
			- nu se permite stergerea unui cod de nomenclator daca exista documente pe codul respectiv
		**/
		if exists (select 1 from deleted) and not exists(select 1 from inserted)
			if exists(select 1 from DELETED d join pozdoc p on d.cod=p.cod)
				raiserror ('Nu puteti sterge un cod de nomenclator pe care exista documente!', 16, 1)

		/** 
			Cazul actualizari
				- daca codul de nomenclator are documente nu permite actualizare codului
		**/		
		if exists(select 1 from DELETED) and exists(select 1 from INSERTED)
			if  exists (select 1 from DELETED d join pozdoc p on d.cod=p.cod)
				raiserror ('Nu puteti actualiza un cod de nomenclator pe care exista documente!', 16, 1)
	END
end try

begin catch
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch

GO
create trigger yso_insnomencl on nomencl instead of insert as

INSERT INTO nomencl
	(Cod
	,Tip
	,Denumire
	,UM
	,UM_1
	,Coeficient_conversie_1
	,UM_2
	,Coeficient_conversie_2
	,Cont
	,Grupa
	,Valuta
	,Pret_in_valuta
	,Pret_stoc
	,Pret_vanzare
	,Pret_cu_amanuntul
	,Cota_TVA
	,Stoc_limita
	,Stoc
	,Greutate_specifica
	,Furnizor
	,Loc_de_munca
	,Gestiune
	,Categorie
	,Tip_echipament)
SELECT 
	Cod
	,Tip
	,Denumire
	,UM
	,UM_1
	,Coeficient_conversie_1
	,UM_2
	,Coeficient_conversie_2
	,Cont
	,Grupa
	,Valuta
	,Pret_in_valuta
	,Pret_stoc
	,Pret_vanzare
	,Pret_cu_amanuntul
	,Cota_TVA
	,Stoc_limita
	,Stoc
	,Greutate_specifica
	,Furnizor
	,RTRIM(cod)
	,Gestiune
	,Categorie
	,Tip_echipament
  FROM inserted

