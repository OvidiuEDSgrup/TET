CREATE TABLE [dbo].[functii] (
    [Cod_functie]     CHAR (6)  NOT NULL,
    [Denumire]        CHAR (30) NOT NULL,
    [Nivel_de_studii] CHAR (10) NOT NULL,
    [detalii]         XML       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_functia]
    ON [dbo].[functii]([Cod_functie] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[functii]([Denumire] ASC);


GO
--***
create trigger tr_validFunctii on functii for insert, update, delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	if (select max(case when i.Cod_functie is null and (ip.Cod_functie is not null or p.Cod_functie is not null) then '' else 'corect' end)
		from deleted d
			left outer join inserted i on d.Cod_functie=i.Cod_functie
			left outer join istPers ip on ip.Cod_functie=d.Cod_functie
			left outer join personal p on p.Cod_functie=d.Cod_functie)=''
		raiserror('Eroare operare (functii.tr_validFunctii): Acest cod de functie este atasat salariatilor!',16,1)	
		
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from functii
--sp_help functii
