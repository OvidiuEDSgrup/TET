CREATE TABLE [dbo].[tichete] (
    [Marca]            CHAR (6)   NOT NULL,
    [Data_lunii]       DATETIME   NOT NULL,
    [Tip_operatie]     CHAR (1)   NOT NULL,
    [Serie_inceput]    CHAR (13)  NOT NULL,
    [Serie_sfarsit]    CHAR (13)  NOT NULL,
    [Nr_tichete]       REAL       NOT NULL,
    [Valoare_tichet]   FLOAT (53) NOT NULL,
    [Valoare_imprimat] FLOAT (53) NOT NULL,
    [TVA_imprimat]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tichete_masa]
    ON [dbo].[tichete]([Marca] ASC, [Data_lunii] ASC, [Tip_operatie] ASC, [Serie_inceput] ASC);


GO
--***
CREATE trigger tichetesterg on tichete for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysstich
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A', Marca,Data_lunii,Tip_operatie,Serie_inceput,Serie_sfarsit,Nr_tichete,Valoare_tichet,Valoare_imprimat,TVA_imprimat
   from inserted 
   
insert into sysstich
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S', Marca,Data_lunii,Tip_operatie,Serie_inceput,Serie_sfarsit,Nr_tichete,Valoare_tichet,Valoare_imprimat,TVA_imprimat
   from deleted
end

GO
--***
create trigger tr_ValidTichete on Tichete for insert,update,delete NOT FOR REPLICATION as
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
	select DISTINCT Data_lunii, 'TICHETE' from inserted
	union all
	select DISTINCT Data_lunii, 'TICHETE' from deleted
	exec validLunaInchisaSalarii

	if UPDATE(Marca) --Verificam consistenta marci ca si marca din personal
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data_lunii) from INSERTED 
		exec validMarcaSalarii

--	apelare validLM pentru validare loc de munca invalidat
		create table #lm (utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm (utilizator,cod,data)
		select distinct @userASiS,p.loc_de_munca,data_lunii from inserted i inner join personal p on i.Marca=p.Marca
		exec validLMSalarii
	end 

	if UPDATE(Tip_operatie) --Verificam consistenta tipului de operatie
	begin
		if exists (select 1 from inserted i where i.Tip_operatie='')
			raiserror('Eroare operare: Tip operatie necompletat!',16,1)
			
		if exists (select 1 from inserted i where i.Tip_operatie='X')
			and not exists (select 1 from inserted i inner join extinfop e on e.Marca=i.Marca and e.Cod_inf='TICHSOCIALE' where upper(e.Val_inf)='DA')
			raiserror('Eroare operare: Tip operatie nepermis! Acest salariat nu beneficiaza de tichete sociale',16,1)
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidTichete)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
