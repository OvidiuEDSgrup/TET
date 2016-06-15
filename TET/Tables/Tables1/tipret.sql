CREATE TABLE [dbo].[tipret] (
    [Subtip]                 CHAR (4)  NOT NULL,
    [Denumire]               CHAR (30) NOT NULL,
    [Tip_retinere]           CHAR (1)  NOT NULL,
    [Obiect_subtip_retinere] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Subtip]
    ON [dbo].[tipret]([Subtip] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip]
    ON [dbo].[tipret]([Tip_retinere] ASC, [Subtip] ASC);


GO
--***
create trigger tr_validTipret on tipret for insert, update, delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	if (select max(case when i.Subtip is null and b.Cod_beneficiar is not null then '' else 'corect' end)
		from deleted d
		left outer join inserted i on d.Subtip=i.Subtip
		left outer join benret b on b.Tip_retinere=d.Subtip)=''
		raiserror('Eroare operare: Acest tip de retinere este atasat unui beneficiar de retinere!',16,1)
		
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_validTipret)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from tipret
--sp_help tipret
