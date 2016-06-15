CREATE TABLE [dbo].[ProgramLucru] (
    [idProgramDeLucru] INT          IDENTITY (1, 1) NOT NULL,
    [Loc_de_munca]     VARCHAR (9)  NULL,
    [Marca]            VARCHAR (6)  NULL,
    [Tip_programare]   VARCHAR (20) NULL,
    [Tip_ore_pontaj]   VARCHAR (3)  NULL,
    [Data_inceput]     DATETIME     NULL,
    [Ora_start]        VARCHAR (6)  NULL,
    [Data_sfarsit]     DATETIME     NULL,
    [Ora_stop]         VARCHAR (6)  NULL,
    [Ore_munca]        INT          NULL,
    [Ore_odihna]       INT          NULL,
    [detalii]          XML          NULL,
    PRIMARY KEY CLUSTERED ([idProgramDeLucru] ASC)
);


GO
--***
create trigger tr_ValidProgramLucru on ProgramLucru for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	if UPDATE(Marca) --Verificam consistenta marcii in raport cu tabela personal, daca este vorba de program de lucru pe salariat
	begin
		if exists (select 1 from inserted i where isnull(i.marca,'')<>'')
			and not exists (select 1 from inserted i inner join personal p on i.Marca=p.Marca)
			raiserror('Eroare operare (ProgramLucru.tr_ValidProgramLucru): Marca inexistenta in catalogul de personal!',16,1)

		if exists (select 1 from inserted i inner join personal p on i.Marca=p.Marca where isnull(i.Marca,'')<>'' and p.Data_angajarii_in_unitate>i.data_inceput)
		Begin
			select @mesajeroare='Eroare operare (tr_ValidProgramLucru.tr_ValidProgramLucru): Salariatul selectat este angajat abia incepand cu data de '
				+convert(char(10),p.Data_angajarii_in_unitate,103)+' !'
			from inserted i inner join personal p on i.Marca=p.Marca 
			where isnull(i.Marca,'')<>'' and p.Data_angajarii_in_unitate>dbo.eom(i.data_inceput)
			raiserror(@mesajeroare,16,1)
		End	

		if exists (select 1 from inserted i inner join personal p on i.Marca=p.Marca where isnull(i.Marca,'')<>'' and convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec<i.data_inceput)
		Begin
			select @mesajeroare='Eroare operare (ProgramLucru.tr_ValidProgramLucru): Salariatul selectat este plecat din unitate la '+convert(char(10),p.Data_plec,103)+' !'
			from inserted i inner join personal p on i.Marca=p.Marca 
			where isnull(i.Marca,'')<>'' and convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec<i.data_inceput
			raiserror(@mesajeroare,16,1)
		End	
	end 

	if UPDATE(Loc_de_munca) --Verificam consistenta locului de munca in raport cu tabela lm, daca este vorba de program de lucru pe loc de munca
	begin
		if exists (select 1 from inserted i where isnull(i.Loc_de_munca,'')<>'')
			and not exists (select 1 from inserted i inner join lm on i.Loc_de_munca=lm.Cod)
			raiserror('Eroare operare (ProgramLucru.tr_ValidProgramLucru): Loc de munca inexistent in catalog!',16,1)
	end

	if UPDATE(Data_inceput) or UPDATE(Data_sfarsit) --Verificam consistenta perioadei 
	begin
		if exists (select 1 from inserted i where Data_inceput>isnull(Data_sfarsit,'12/31/2999'))
			raiserror('Eroare operare (ProgramLucru.tr_ValidProgramLucru): Data de sfarsit nu poate fi mai mica decat data de inceput!',16,1)
	end 

end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
