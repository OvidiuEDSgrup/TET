CREATE TABLE [dbo].[webConfigTaburi] (
    [MeniuSursa]     VARCHAR (50)  NOT NULL,
    [TipSursa]       VARCHAR (50)  NOT NULL,
    [NumeTab]        VARCHAR (100) NOT NULL,
    [Icoana]         VARCHAR (500) NULL,
    [TipMachetaNoua] VARCHAR (20)  NULL,
    [MeniuNou]       VARCHAR (20)  NULL,
    [TipNou]         VARCHAR (20)  NULL,
    [ProcPopulare]   VARCHAR (100) NULL,
    [Ordine]         SMALLINT      NULL,
    [Vizibil]        BIT           NULL,
    [detalii]        XML           NULL,
    [publicabil]     INT           NULL
) ON [WEB];


GO
--***
create trigger webconfigtaburi_tr
	on webconfigtaburi
	after insert, update, delete
as
	--> pentru a detecta mai usor tipul operatiei, in caz de update se adauga '/update' la sfarsit:
declare @insert varchar(100),
		@delete varchar(100)
select @insert='insert',
		@delete='delete'
if (select count(1) from inserted)>0 and (select count(1) from deleted)>0
	select @insert=@insert+'/update', @delete=@delete+'/update'

	--> jurnalizarea:
insert into sysswebconfigtaburi
(user_name, host_name, program_name, tip_operatie, data_modificarii, MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, publicabil, detalii)
select suser_name(), host_name(), program_name(), @delete, getdate(), MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, publicabil, detalii
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, publicabil, detalii
	from inserted