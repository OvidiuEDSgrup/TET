CREATE TABLE [dbo].[webConfigForm] (
    [Meniu]         VARCHAR (20)  NOT NULL,
    [Tip]           VARCHAR (2)   NULL,
    [Subtip]        VARCHAR (2)   NULL,
    [Ordine]        INT           NULL,
    [Nume]          VARCHAR (50)  NULL,
    [TipObiect]     VARCHAR (50)  NULL,
    [DataField]     VARCHAR (50)  NULL,
    [LabelField]    VARCHAR (50)  NULL,
    [Latime]        INT           NULL,
    [Vizibil]       BIT           NULL,
    [Modificabil]   BIT           NULL,
    [ProcSQL]       VARCHAR (50)  NULL,
    [ListaValori]   VARCHAR (100) NULL,
    [ListaEtichete] VARCHAR (600) NULL,
    [Initializare]  VARCHAR (50)  NULL,
    [Prompt]        VARCHAR (50)  NULL,
    [Procesare]     VARCHAR (50)  NULL,
    [Tooltip]       VARCHAR (500) NULL,
    [formula]       VARCHAR (MAX) NULL,
    [detalii]       XML           NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigForm]
    ON [dbo].[webConfigForm]([Meniu] ASC, [Tip] ASC, [Subtip] ASC, [DataField] ASC)
    ON [WEB];


GO
--***
create trigger webconfigform_tr
	on webconfigform
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
insert into syssWebConfigForm
(user_name, host_name, program_name, tip_operatie, data_modificarii,  Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, detalii)
select suser_name(), host_name(), program_name(), @delete, getdate(), Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, detalii
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, detalii
	from inserted