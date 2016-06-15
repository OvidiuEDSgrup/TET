CREATE TABLE [dbo].[conmed] (
    [Data]                     DATETIME   NOT NULL,
    [Marca]                    CHAR (6)   NOT NULL,
    [Tip_diagnostic]           CHAR (2)   NOT NULL,
    [Data_inceput]             DATETIME   NOT NULL,
    [Data_sfarsit]             DATETIME   NOT NULL,
    [Zile_lucratoare]          SMALLINT   NOT NULL,
    [Zile_cu_reducere]         SMALLINT   NOT NULL,
    [Zile_luna_anterioara]     SMALLINT   NOT NULL,
    [Indemnizatia_zi]          FLOAT (53) NOT NULL,
    [Procent_aplicat]          REAL       NOT NULL,
    [Indemnizatie_unitate]     FLOAT (53) NOT NULL,
    [Indemnizatie_CAS]         FLOAT (53) NOT NULL,
    [Baza_calcul]              FLOAT (53) NOT NULL,
    [Zile_lucratoare_in_luna]  SMALLINT   NOT NULL,
    [Indemnizatii_calc_manual] BIT        NOT NULL,
    [Suma]                     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[conmed]([Data] ASC, [Marca] ASC, [Data_inceput] ASC);


GO
--***
CREATE trigger conmedsterg on conmed for insert, update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysscm
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
			'A', Data, Marca, Tip_diagnostic, Data_inceput, Data_sfarsit, Zile_lucratoare,Zile_cu_reducere, Zile_luna_anterioara, 
                  Indemnizatia_zi, Procent_aplicat, Indemnizatie_unitate, Indemnizatie_CAS, Baza_calcul, Zile_lucratoare_in_luna,
                  Indemnizatii_calc_manual, Suma
   from inserted
   
insert into sysscm
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
			'S', Data, Marca, Tip_diagnostic, Data_inceput, Data_sfarsit, Zile_lucratoare,                   Zile_cu_reducere, Zile_luna_anterioara, 
                  Indemnizatia_zi, Procent_aplicat, Indemnizatie_unitate, Indemnizatie_CAS, Baza_calcul, Zile_lucratoare_in_luna,
                  Indemnizatii_calc_manual, Suma
   from deleted
end

GO
--***
create trigger tr_ValidConmed on conmed for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(1000)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	declare @userASiS varchar(50), @nume_tabela varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)
	set @nume_tabela='(CONMED-Concedii medicale)'

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
		create table #lm (utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm (utilizator,cod,data)
		select distinct @userASiS,p.loc_de_munca,data from inserted i inner join personal p on i.Marca=p.Marca
		exec validLMSalarii
	end 

	/* Validare tip diagnostic */
	if UPDATE(Tip_diagnostic) 
	begin
		if exists (select 1 from inserted i where i.Tip_diagnostic='')
			raiserror('Eroare operare: Tip diagnostic necompletat!',16,1)

		if exists (select 1 from inserted i where i.Tip_diagnostic not in ('0-','1-','2-','3-','4-','5-','6-','7-','8-','9-','10','11','12','13','14','15'))
			raiserror('Eroare operare: Tip diagnostic incorect!',16,1)
	end

	/* Validari specifice concediilor */
	if UPDATE(Data_inceput) or UPDATE(Data_sfarsit) 
	begin
		declare @OperareCMLuniAnt int
		set @OperareCMLuniAnt=dbo.iauParL('PS','OPCMLANT')
		if @OperareCMLuniAnt=0 and exists (select 1 from inserted i where dbo.eom(i.Data_inceput)<>dbo.eom(i.Data) or dbo.eom(i.Data_sfarsit)<>dbo.eom(i.Data))
			raiserror('Eroare operare: Data de inceput/sfarsit trebuie sa fie in luna de lucru!',16,1)

		create table #concedii (data datetime, marca varchar(6), tip_concediu varchar(2), data_inceput datetime, data_sfarsit datetime, fel varchar(2), nume_tabela varchar(50))
		insert into #concedii (data, marca, tip_concediu, data_inceput, data_sfarsit, fel, nume_tabela)
		select data, marca, tip_diagnostic, data_inceput, data_sfarsit, 'CM', @nume_tabela 
		from inserted
		exec validConcedii
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidConmed)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
