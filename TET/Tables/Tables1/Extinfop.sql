CREATE TABLE [dbo].[Extinfop] (
    [Marca]    CHAR (6)   NOT NULL,
    [Cod_inf]  CHAR (13)  NOT NULL,
    [Val_inf]  CHAR (80)  NOT NULL,
    [Data_inf] DATETIME   NOT NULL,
    [Procent]  FLOAT (53) NOT NULL,
    [detalii]  XML        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[Extinfop]([Marca] ASC, [Cod_inf] ASC, [Val_inf] ASC, [Data_inf] ASC);


GO
CREATE NONCLUSTERED INDEX [Valoare_proprietate]
    ON [dbo].[Extinfop]([Val_inf] ASC);


GO
CREATE NONCLUSTERED INDEX [Marca_Cod]
    ON [dbo].[Extinfop]([Marca] ASC, [Cod_inf] ASC);


GO
--***
create trigger tr_ValidExtinfop on Extinfop for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(1000)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	if UPDATE(Cod_inf) --Verificam consistenta codului de informatie, la fel va fi pe celelalte campuri
	begin
		if (select min(case when i.Cod_inf not in ('#CODCOR','SALINLOCIN','SALINLOCSF','DETDATAINC','DETDATASF','DETNATIONAL','AUTDATAINC','AUTDATASF','SCDATAINC','SCDATASF','SCDATAINCET','EXCEPDATASF') 
			and c.Cod is null then '' else 'corect' end)
		from inserted i
		left outer join Catinfop c on i.Cod_inf=c.Cod)=''
		begin
			select @mesajeroare='Eroare operare (extinfop.tr_ValidExtinfop): Cod informatie ('+rtrim(i.Cod_inf)+') neintrodus sau inexistent in catalogul de informatii!'
			from inserted i
				left outer join Catinfop c on i.Cod_inf=c.Cod
			where i.Cod_inf not in ('#CODCOR','SALINLOCIN','SALINLOCSF','DETDATAINC','DETDATASF','DETNATIONAL','AUTDATAINC','AUTDATASF','SCDATAINC','SCDATASF','SCDATAINCET','EXCEPDATASF') 
				and c.Cod is null
			raiserror(@mesajeroare,16,1)
		end
	end 

	if UPDATE(Marca) --Verificam consistenta marci ca si marca din personal/cod functie ASiS
	begin
		if (select min(case when i.Cod_inf not in ('#CODCOR','#CASSAN') and p.Marca is null then '' else 'corect' end)
		from inserted i
		left outer join personal p on i.Marca=p.Marca)=''
			raiserror('Eroare operare (extinfop.tr_ValidExtinfop): Marca neintrodusa sau inexistenta in catalogul de personal!',16,1)

		if (select min(case when i.Cod_inf='#CODCOR' and f.Cod_functie is null then '' else 'corect' end)
		from inserted i
		left outer join functii f on i.Marca=f.Cod_functie)=''
			raiserror('Eroare operare (extinfop.tr_ValidExtinfop): Cod functie neintrodus sau inexistent in catalogul de functii!',16,1)
	end 


	if UPDATE(Val_inf) --Verificam consistenta valorii informatiei: ca si cod functie COR/daca cod informatie este de tip validat
	begin
		if (select min(case when i.Cod_inf='#CODCOR' and f.Cod_functie is null then '' else 'corect' end)
		from inserted i
		left outer join functii_COR f on i.Val_inf=f.Cod_functie where i.Val_inf<>'')=''
			raiserror('Eroare operare (extinfop.tr_ValidExtinfop): Cod functie COR neintrodus sau inexistent in catalogul de functii COR!',16,1)

		if exists (select 1 from inserted i left outer join Catinfop c on c.Cod=i.Cod_inf where c.Tip='V')
		and not exists (select 1 from inserted i left outer join valinfopers v on v.Cod_inf=i.Cod_inf where v.Valoare=i.Val_inf)
			raiserror('Eroare operare (extinfop.tr_ValidExtinfop): Valoare informatie nepermisa! Aceasta valoare nu este atasata codului de informatie selectat!',16,1)
	end 

	if exists (select 1 from inserted i where i.cod_inf='PENSIIF' and i.data_inf<>dbo.BOY(i.data_inf))
	begin
		select @mesajeroare='Eroare operare (extinfop.tr_ValidExtinfop): Pentru codul de informatie "PENSIIF", data informatiei trebuie sa fie egala cu prima zi din an!'
		from inserted i
		where i.Cod_inf='PENSIIF' and i.data_inf<>dbo.BOY(i.data_inf)
		raiserror(@mesajeroare,16,1)
	end

end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
