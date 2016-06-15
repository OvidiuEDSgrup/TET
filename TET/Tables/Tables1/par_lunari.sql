CREATE TABLE [dbo].[par_lunari] (
    [Data]               DATETIME   NOT NULL,
    [Tip]                CHAR (2)   NOT NULL,
    [Parametru]          CHAR (9)   NOT NULL,
    [Denumire_parametru] CHAR (30)  NOT NULL,
    [Val_logica]         BIT        NOT NULL,
    [Val_numerica]       FLOAT (53) NOT NULL,
    [Val_alfanumerica]   CHAR (200) NOT NULL,
    [Val_data]           DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Parametru]
    ON [dbo].[par_lunari]([Data] ASC, [Tip] ASC, [Parametru] ASC);


GO
--***
CREATE trigger parlunaristerg on par_lunari for insert, update, delete  /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspl
	select host_id(), host_name (), @Aplicatia, getdate(), @Utilizator,
	'A', Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data
   from inserted

insert into sysspl
	select host_id(), host_name (), @Aplicatia, getdate(), @Utilizator,
	'S', Data, Tip, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica, Val_data
   from deleted	
