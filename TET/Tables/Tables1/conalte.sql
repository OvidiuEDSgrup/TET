CREATE TABLE [dbo].[conalte] (
    [Data]          DATETIME   NOT NULL,
    [Marca]         CHAR (6)   NOT NULL,
    [Tip_concediu]  CHAR (1)   NOT NULL,
    [Data_inceput]  DATETIME   NOT NULL,
    [Data_sfarsit]  DATETIME   NOT NULL,
    [Zile]          SMALLINT   NOT NULL,
    [Introd_manual] BIT        NOT NULL,
    [Indemnizatie]  FLOAT (53) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[conalte]([Data] ASC, [Marca] ASC, [Data_inceput] ASC, [Tip_concediu] ASC);


GO
--***
create trigger tr_ValidConalte on conalte for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(1000)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	declare @userASiS varchar(50), @nume_tabela varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)
	set @nume_tabela='(CONALTE-Concedii alte)'

	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, @nume_tabela from inserted
	union all
	select DISTINCT Data, @nume_tabela from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca)
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED 
		exec validMarcaSalarii

--	apelare validLM pentru validare loc de munca invalidat
		create table #lm (utilizator varchar(50), cod varchar(20), data datetime)
		insert into #lm (utilizator, cod, data)
		select distinct @userASiS, p.loc_de_munca, data 
		from inserted i inner join personal p on i.Marca=p.Marca
		exec validLMSalarii
	end 

	/* Validari specifice concediilor */
	if UPDATE(Data_inceput) or UPDATE(Data_sfarsit) or UPDATE(Tip_concediu)
	begin
		create table #concedii (data datetime, marca varchar(6), tip_concediu varchar(2), data_inceput datetime, data_sfarsit datetime, fel varchar(2), nume_tabela varchar(50))
		insert into #concedii (data, marca, tip_concediu, data_inceput, data_sfarsit, fel, nume_tabela)
		select data, marca, tip_concediu, data_inceput, data_sfarsit, 'CA', @nume_tabela 
		from inserted
		where CHARINDEX(Tip_concediu,'5ABCDEN')=0 
		exec validConcedii
	end 

	/* Validare tip concediu */
	if UPDATE(Tip_concediu) 
	begin
		if exists (select 1 from inserted i where not exists (select 1 from fTip_ConcediiAlte() where Tip_concediu=i.Tip_concediu))
			raiserror('Eroare operare: Tip concediu incorect!',16,1)
	end 

	if UPDATE(Indemnizatie) --Verificam consistenta campului de ore (pt. nemotivate)
	begin
		if exists (select 1 from inserted i where i.Indemnizatie<>0 and i.tip_concediu not in ('A','B','C','D','E','N') 
			and not(i.Tip_concediu in ('2','3') and convert(char(10),i.Data_inceput,101)=convert(char(10),i.Data_sfarsit,101)))
			raiserror('Eroare operare: Campul ore se completeaza doar pt. tipurile 2-Nemotivate sau 3-Invoiri si daca data de inceput este egala cu data de sfarsit!',16,1)

		if exists (select 1 from inserted i 
		left outer join personal p on p.Marca=i.Marca where i.Tip_concediu in ('2','3') and i.Data_inceput=i.Data_sfarsit and i.Indemnizatie<>0 and i.Indemnizatie>=p.Salar_lunar_de_baza)
			raiserror('Eroare operare: Campul ore trebuie sa fie mai mic decat regimul de lucru al salariatului!',16,1)
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidConalte)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger conaltesterg on conalte for insert, update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssca
	select host_id(), host_name (), @Aplicatia, getdate(), @Utilizator,
	'A', Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie
	from inserted
insert into syssca
	select host_id(), host_name (), @Aplicatia, getdate(), @Utilizator, 
	'S', Data, Marca, Tip_concediu, Data_inceput, Data_sfarsit, Zile, Introd_manual, Indemnizatie
	from deleted
end
