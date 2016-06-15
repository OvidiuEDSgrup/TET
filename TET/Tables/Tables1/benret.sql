CREATE TABLE [dbo].[benret] (
    [Cod_beneficiar]      CHAR (13)    NOT NULL,
    [Tip_retinere]        CHAR (1)     NOT NULL,
    [Denumire_beneficiar] CHAR (30)    NOT NULL,
    [Obiect_retinere]     CHAR (50)    NOT NULL,
    [Cod_fiscal]          CHAR (10)    NOT NULL,
    [Banca]               CHAR (30)    NOT NULL,
    [Cont_banca]          CHAR (30)    NOT NULL,
    [Permane]             BIT          NOT NULL,
    [Cont_debitor]        VARCHAR (20) NULL,
    [Cont_creditor]       VARCHAR (20) NULL,
    [Analitic_marca]      BIT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[benret]([Cod_beneficiar] ASC);


GO
--***
create trigger tr_validBenret on benret for insert, update, delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	if (select max(case when i.Cod_beneficiar is null and r.Cod_beneficiar is not null then '' else 'corect' end)
		from deleted d
		left outer join inserted i on d.Cod_beneficiar=i.Cod_beneficiar
		left outer join resal r on r.Cod_beneficiar=d.Cod_beneficiar)=''
		raiserror('Eroare operare (benret.tr_validBenret): Acest cod de beneficiar are retineri inregistrate!',16,1)	
		
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from benret
--sp_help benret
