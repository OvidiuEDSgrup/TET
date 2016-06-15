CREATE TABLE [dbo].[avexcep] (
    [Marca]                CHAR (6)   NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Ore_lucrate_la_avans] SMALLINT   NOT NULL,
    [Suma_avans]           FLOAT (53) NOT NULL,
    [Premiu_la_avans]      FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[avexcep]([Data] ASC, [Marca] ASC);


GO
--***
CREATE trigger avexcepsterg on avexcep for insert, update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssavx
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'A', Marca, Data, Ore_lucrate_la_avans, Suma_avans, Premiu_la_avans
   from inserted
    insert into syssavx
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S', Marca, Data, Ore_lucrate_la_avans, Suma_avans, Premiu_la_avans
   from deleted
end

GO
--***
create trigger tr_ValidAvexcep on avexcep for insert,update,delete NOT FOR REPLICATION as
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
	select DISTINCT Data, 'AVEXCEP - Avans exceptie' from inserted
	union all
	select DISTINCT Data, 'AVEXCEP - Avans exceptie' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca */
	if UPDATE(Marca)
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED 
		exec validMarcaSalarii

--	apelare validLM pentru validare loc de munca invalidat
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @userASiS,p.loc_de_munca,data from inserted i inner join personal p on i.Marca=p.Marca
		exec validLMSalarii
	end 

	if UPDATE(Ore_lucrate_la_avans) --Verificam consistenta campului Ore lucrate la avans
	begin
		declare @CalcAvansMarca int
		exec luare_date_par 'PS','CAV_MARCA',@CalcAvansMarca output,0,''
		if @CalcAvansMarca=1 and exists (select 1 from inserted where Ore_lucrate_la_avans>1)
			raiserror('Eroare operare: Valorile permise sunt 0=Nu si 1=Da!',16,1)
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidAvexcep)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
