CREATE TABLE [dbo].[infoPers] (
    [Marca]                   CHAR (6)     NOT NULL,
    [Permis_auto_categoria]   CHAR (10)    NOT NULL,
    [Limbi_straine]           CHAR (30)    NOT NULL,
    [Nationalitatea]          CHAR (10)    NOT NULL,
    [Cetatenia]               CHAR (10)    NOT NULL,
    [Starea_civila]           CHAR (1)     NOT NULL,
    [Marca_sot_sotie]         CHAR (6)     NOT NULL,
    [Nume_sot_sotie]          CHAR (30)    NOT NULL,
    [Religia]                 VARCHAR (25) NULL,
    [Evidenta_militara]       CHAR (1)     NOT NULL,
    [Telefon]                 CHAR (15)    NOT NULL,
    [Email]                   CHAR (50)    NOT NULL,
    [Observatii]              CHAR (100)   NOT NULL,
    [Actionar]                BIT          NOT NULL,
    [Centru_de_cost_exceptie] CHAR (13)    NOT NULL,
    [Vechime_studii]          CHAR (6)     NOT NULL,
    [Poza]                    IMAGE        NULL,
    [Loc_munca_precedent]     CHAR (40)    NOT NULL,
    [Loc_munca_nou]           CHAR (40)    NOT NULL,
    [Vechime_la_intrare]      CHAR (6)     NOT NULL,
    [Vechime_in_meserie]      CHAR (6)     NOT NULL,
    [Nr_contract]             CHAR (20)    NOT NULL,
    [Spor_cond_7]             FLOAT (53)   NOT NULL,
    [Spor_cond_8]             FLOAT (53)   NOT NULL,
    [Spor_cond_9]             FLOAT (53)   NOT NULL,
    [Spor_cond_10]            FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[infoPers]([Marca] ASC);


GO
--***
CREATE trigger infoperssterg on infoPers for insert, update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssip
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	'A', Marca, Permis_auto_categoria, Limbi_straine, Nationalitatea, Cetatenia, Starea_civila, 
	Marca_sot_sotie, Nume_sot_sotie, Religia, Evidenta_militara, Telefon, Email, Observatii, 
	Actionar, Centru_de_cost_exceptie, Vechime_studii, Loc_munca_precedent, Loc_munca_nou, 
	Vechime_la_intrare, Vechime_in_meserie, Nr_contract, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
   from inserted
   
insert into syssip
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	'S', Marca, Permis_auto_categoria, Limbi_straine, Nationalitatea, Cetatenia, Starea_civila, 
	Marca_sot_sotie, Nume_sot_sotie, Religia, Evidenta_militara, Telefon, Email, Observatii, 
	Actionar, Centru_de_cost_exceptie, Vechime_studii, Loc_munca_precedent, Loc_munca_nou, 
	Vechime_la_intrare, Vechime_in_meserie, Nr_contract, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
   from deleted

GO
--***
create  trigger tr_validInfopers on infopers for insert,update NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255),@validcomstrictGE int,@salariatiPecomenzi int
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	
	if UPDATE(Centru_de_cost_exceptie) 
	begin
		exec luare_date_par 'GE', 'COMANDA', 0, @validcomstrictGE output, ''
		exec luare_date_par 'PS', 'SALCOM', @salariatiPecomenzi output, 0, ''	
		
		if @validcomstrictGE=1 and @salariatiPecomenzi=1 and exists(select 1 from inserted where isnull(inserted.Centru_de_cost_exceptie,'')='')
			raiserror('Eroare operare: Comanda necompletata!',16,1)
		
		if exists(select 1 from inserted where isnull(inserted.Centru_de_cost_exceptie,'')<>'') 
			and not exists(select 1 from inserted inner join comenzi on comenzi.Comanda=inserted.Centru_de_cost_exceptie) 
			raiserror('Eroare operare: Comanda inexistenta in tabela de comenzi!',16,1)
		
	end 
	
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+' (tr_validInfopers)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
--select * from infopers
--select * from comenzi
