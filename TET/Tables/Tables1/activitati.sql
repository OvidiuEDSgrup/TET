CREATE TABLE [dbo].[activitati] (
    [Tip]           CHAR (2)  NOT NULL,
    [Fisa]          CHAR (20) NOT NULL,
    [Data]          DATETIME  NOT NULL,
    [Masina]        CHAR (20) NOT NULL,
    [Comanda]       CHAR (13) NOT NULL,
    [Loc_de_munca]  CHAR (9)  NOT NULL,
    [Comanda_benef] CHAR (13) NOT NULL,
    [lm_benef]      CHAR (9)  NOT NULL,
    [Tert]          CHAR (13) NOT NULL,
    [Marca]         CHAR (6)  NOT NULL,
    [Marca_ajutor]  CHAR (20) NOT NULL,
    [Jurnal]        CHAR (3)  NOT NULL,
    [idActivitati]  INT       IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [idActivitati] PRIMARY KEY NONCLUSTERED ([idActivitati] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[activitati]([Tip] ASC, [Fisa] ASC, [Data] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Pentru_culegere]
    ON [dbo].[activitati]([Tip] ASC, [Data] ASC, [Fisa] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [Masina]
    ON [dbo].[activitati]([Masina] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Comanda_beneficiar]
    ON [dbo].[activitati]([Tip] ASC, [Fisa] ASC, [Data] ASC, [Comanda_benef] ASC);


GO
--***
create trigger activlunai on activitati for update, insert, delete as
declare @nlunainc int, @nanulinc int, @ddatainc datetime
set @nlunainc= (select val_numerica from par where tip_parametru='MM' and parametru='LUNAINC')
set @nanulinc= (select val_numerica from par where tip_parametru='MM' and parametru='ANULINC')
set @dDataInc=dateadd(month,1,convert(datetime,str(@nLunaInc,2)+'/01/'+str(@nAnulInc,4)))
if (select count(*) from inserted where data<@dDataInc)>0 or (select count(*) from deleted where data<@dDataInc)>0
begin
 RAISERROR ('Violare integritate date. Incercare de modificare luna inchisa(activitati)', 16, 1)
 rollback transaction
end

GO
--***
CREATE trigger activsterg on activitati for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssactiv
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 
		'A', Tip, Fisa, Data, Masina, Comanda, Loc_de_munca, Comanda_benef, lm_benef, Tert, Marca, Marca_ajutor, Jurnal
	from inserted   

insert into syssactiv  
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S',Tip, Fisa, Data, Masina, Comanda, Loc_de_munca, Comanda_benef, lm_benef, Tert, Marca, Marca_ajutor, Jurnal
	from deleted  
end
