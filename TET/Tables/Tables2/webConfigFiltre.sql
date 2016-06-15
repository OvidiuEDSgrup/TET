CREATE TABLE [dbo].[webConfigFiltre] (
    [Meniu]      VARCHAR (20)  NOT NULL,
    [Tip]        VARCHAR (2)   NOT NULL,
    [Ordine]     INT           NULL,
    [Vizibil]    BIT           NOT NULL,
    [TipObiect]  VARCHAR (50)  NULL,
    [Descriere]  VARCHAR (50)  NULL,
    [Prompt1]    VARCHAR (20)  NULL,
    [DataField1] VARCHAR (100) NULL,
    [Interval]   BIT           NULL,
    [Prompt2]    VARCHAR (20)  NULL,
    [DataField2] VARCHAR (100) NULL,
    [detalii]    XML           NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigFiltre]
    ON [dbo].[webConfigFiltre]([Meniu] ASC, [Tip] ASC, [DataField1] ASC)
    ON [WEB];


GO
--***
create trigger webconfigfiltre_tr
	on webconfigfiltre
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
insert into sysswebconfigfiltre
(user_name, host_name, program_name, tip_operatie, data_modificarii, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, detalii)
select suser_name(), host_name(), program_name(), @delete, getdate(), Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, detalii
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, detalii
	from inserted