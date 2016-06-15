CREATE TABLE [dbo].[corectii] (
    [Data]               DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Tip_corectie_venit] CHAR (2)   NOT NULL,
    [Suma_corectie]      FLOAT (53) NOT NULL,
    [Procent_corectie]   REAL       NOT NULL,
    [Suma_neta]          FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[corectii]([Data] ASC, [Marca] ASC, [Loc_de_munca] ASC, [Tip_corectie_venit] ASC);


GO
--***
create trigger tr_ValidCorectii on corectii for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	declare @userASiS varchar(50)
	set @userASiS=dbo.fIaUtilizator(null)

	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'CORECTII' from inserted
	union all
	select DISTINCT Data, 'CORECTII' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca) 
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED where not(Marca='' and Loc_de_munca<>'') --	nu fac validarea in cazul corectiilor pe locuri de munca
		exec validMarcaSalarii
	end 

	/* Validare loc de munca */
	if UPDATE(loc_de_munca) 
	begin
		create table #lm (utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm (utilizator,cod,data)
		select distinct @userASiS,loc_de_munca,data from inserted		
		exec validLMSalarii
	end

	if UPDATE(Tip_corectie_venit) --Verificam consistenta tipului de corectie
	begin
		declare @subtipcor int
		exec luare_date_par 'PS','SUBTIPCOR',@Subtipcor output,0,''
		if exists (select 1 from inserted i where i.Tip_corectie_venit='')
		Begin
			set @mesajeroare='Eroare operare: '+(case when @Subtipcor=0 then 'Tip' else 'Subtip' end)+' corectie venit necompletat!'
			raiserror(@mesajeroare,16,1)
		End	

		if exists (select 1 from inserted i where @Subtipcor=0 and i.Tip_corectie_venit not in (select Tip_corectie_venit from tipcor) or
			@Subtipcor=1 and i.Tip_corectie_venit not in (select subtip from subtipcor))
		Begin
			set @mesajeroare='Eroare operare: '+(case when @Subtipcor=0 then 'Tip' else 'Subtip' end)+' corectie venit incorect!'
			raiserror(@mesajeroare,16,1)
		End	
	end 

	if UPDATE(Suma_corectie) -- Verificam existenta unei singure prime de vacanta pe an
	begin
		declare @PrimaV1An int
		exec luare_date_par 'PS','PV-1AN',@PrimaV1An output,0,''
		if @PrimaV1An=1 and exists (select 1 from inserted) and not exists (select 1 from deleted) 
			and exists (select 1 from inserted i where @Subtipcor=0 and i.Tip_corectie_venit='O-' or @Subtipcor=1 and exists (select 1 from subtipcor s where s.subtip=i.Tip_corectie_venit and s.Tip_corectie_venit='O-'))
			and exists (select 1 from corectii c inner join inserted i on i.Marca=c.Marca where c.Data between dbo.boy(i.Data) and i.Data and c.tip_corectie_venit=i.Tip_corectie_venit and c.Data<>i.Data)
		Begin
			select @mesajeroare='Eroare operare: Corectia prima de vacanta a fost acordata deja pe aceasta marca in luna: '+
			+rtrim(convert(char(2),month(c.Data)))+' - '+convert(char(4),year(c.Data))+' !'
			from corectii c
				inner join inserted i on i.Marca=c.Marca 
			where c.Data between dbo.boy(i.Data) and i.Data and c.Tip_corectie_venit=i.Tip_corectie_venit
			raiserror(@mesajeroare,16,1)
		End	
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidCorectii)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger corectiisterg on corectii for insert, update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysscor
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'A', Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta 
   from inserted
insert into sysscor
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S', Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta 
   from deleted
end
