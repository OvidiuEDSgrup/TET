CREATE TABLE [dbo].[resal] (
    [Data]                        DATETIME   NOT NULL,
    [Marca]                       CHAR (6)   NOT NULL,
    [Cod_beneficiar]              CHAR (13)  NOT NULL,
    [Numar_document]              CHAR (10)  NOT NULL,
    [Data_document]               DATETIME   NOT NULL,
    [Valoare_totala_pe_doc]       FLOAT (53) NOT NULL,
    [Valoare_retinuta_pe_doc]     FLOAT (53) NOT NULL,
    [Retinere_progr_la_avans]     FLOAT (53) NOT NULL,
    [Retinere_progr_la_lichidare] FLOAT (53) NOT NULL,
    [Procent_progr_la_lichidare]  REAL       NOT NULL,
    [Retinut_la_avans]            FLOAT (53) NOT NULL,
    [Retinut_la_lichidare]        FLOAT (53) NOT NULL,
    [detalii]                     XML        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Marca_Cod_Numar]
    ON [dbo].[resal]([Data] ASC, [Marca] ASC, [Cod_beneficiar] ASC, [Numar_document] ASC);


GO
CREATE NONCLUSTERED INDEX [Benef_Marca_Numar]
    ON [dbo].[resal]([Cod_beneficiar] ASC, [Marca] ASC, [Numar_document] ASC);


GO
--***
create trigger tr_ValidResal on Resal for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int, @mesaj varchar(255), @mesajeroare varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try	
	/** Validare luna inchisa/blocata Salarii */
	create table #lunasalarii (data datetime, nume_tabela varchar(50))
	insert into #lunasalarii (data, nume_tabela)
	select DISTINCT Data, 'RESAL-Retineri' from inserted
	union all
	select DISTINCT Data, 'RESAL-Retineri' from deleted
	exec validLunaInchisaSalarii

	/* Validare marca, cu exceptia pozitiei pe care se pastreaza suma retinuta cu chitanta */
	if UPDATE(Marca) 
	begin
		create table #marci (marca varchar(20), data datetime)
		insert into #marci (marca, data)
		select i.marca, dbo.BOM(i.data) from INSERTED i
			left outer join personal p on p.Marca=i.Marca
		where not(convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec<dbo.bom(i.Data) and YEAR(i.Data)>3000)
		exec validMarcaSalarii
	end 

	if UPDATE(Cod_beneficiar) --Verificam consistenta codului de beneficiar retinere
	begin
		if not exists (select 1 from inserted i inner join benret b on i.Cod_beneficiar=b.Cod_beneficiar)
			raiserror('Eroare operare: Cod beneficiar retinere neintrodus sau inexistent in catalogul de beneficiari retineri!',16,1)
	end 
end try

begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_ValidResal)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger resalsterg on resal for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

    insert into syssret
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	'A', Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare
   from inserted 
    insert into syssret	
    select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
    'S', Data, Marca, Cod_beneficiar, Numar_document, Data_document,  Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare
   from deleted
end
