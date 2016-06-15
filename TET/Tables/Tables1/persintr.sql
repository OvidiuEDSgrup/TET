CREATE TABLE [dbo].[persintr] (
    [Marca]          CHAR (6)  NOT NULL,
    [Tip_intretinut] CHAR (1)  NOT NULL,
    [Cod_personal]   CHAR (13) NOT NULL,
    [Nume_pren]      CHAR (50) NOT NULL,
    [Data]           DATETIME  NOT NULL,
    [Grad_invalid]   CHAR (1)  NOT NULL,
    [Coef_ded]       REAL      NOT NULL,
    [Data_nasterii]  DATETIME  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[persintr]([Marca] ASC, [Cod_personal] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume]
    ON [dbo].[persintr]([Nume_pren] ASC);


GO
--***
create trigger tr_ValidPersintr on persintr for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'PERSINTR-Persoane intretinere' from inserted
	union all
	select DISTINCT Data, 'PERSINTR-Persoane intretinere' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca / validare in raport cu data angajarii/plecarii */
	if UPDATE(Marca) 
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select marca, dbo.BOM(data) from INSERTED 
		exec validMarcaSalarii
	end 

	if UPDATE(Tip_intretinut) --Verificam consistenta tipului de persoana in intretinere
	begin
		if exists (select 1 from inserted i where i.Tip_intretinut='')
			raiserror('Eroare operare: Tip intretinut necompletat!',16,1)
	end 

	if UPDATE(Nume_pren) --Verificam consistenta tipului de persoana in intretinere
	begin
		if exists (select 1 from inserted i where i.Nume_pren='')
			raiserror('Eroare operare: Nume persoana in intretinere necompletat!',16,1)
	end 

	if UPDATE(Cod_personal) --Verificam consistenta codului numeric personal
	begin
		declare @cnp varchar(13), @eroare int
		select @cnp=i.cod_personal from inserted i
		if @cnp=''
		Begin
			set @eroare=2
			set @mesajeroare='Eroare operare: Cod numeric personal necompletat!'
		End	
		if dbo.validare_cnp(@cnp)='1' 
		Begin
			set @eroare=1
			set @mesajeroare='Eroare operare: Cod numeric personal incorect '+'('+@cnp+')!'
		End	
		if @eroare<>0
			raiserror(@mesajeroare,16,1)
	end 

end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidPersintr)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger persintrsterg on persintr for update, delete NOT FOR REPLICATION as
begin
	declare @Utilizator char(10), @Aplicatia char(30)

	set @Utilizator=dbo.fIauUtilizatorCurent()
	select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
	set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

	insert into sysspi
		select host_id(), host_name (), @Aplicatia, getdate(), @Utilizator,
		Marca, Tip_intretinut, Cod_personal, Nume_pren, Data, Grad_invalid, Coef_ded, Data_nasterii
	from deleted
end
