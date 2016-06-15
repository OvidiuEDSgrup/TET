CREATE TABLE [dbo].[webConfigTipuri] (
    [Meniu]                VARCHAR (20)  NOT NULL,
    [Tip]                  VARCHAR (20)  NOT NULL,
    [Subtip]               VARCHAR (20)  NOT NULL,
    [Ordine]               INT           NOT NULL,
    [Nume]                 VARCHAR (50)  NULL,
    [Descriere]            VARCHAR (500) NULL,
    [TextAdaugare]         VARCHAR (60)  NULL,
    [TextModificare]       VARCHAR (60)  NULL,
    [ProcDate]             VARCHAR (60)  NULL,
    [ProcScriere]          VARCHAR (60)  NULL,
    [ProcStergere]         VARCHAR (60)  NULL,
    [ProcDatePoz]          VARCHAR (60)  NULL,
    [ProcScrierePoz]       VARCHAR (60)  NULL,
    [ProcStergerePoz]      VARCHAR (60)  NULL,
    [Vizibil]              BIT           NULL,
    [Fel]                  VARCHAR (1)   NULL,
    [procPopulare]         VARCHAR (60)  NULL,
    [tasta]                VARCHAR (20)  NULL,
    [ProcInchidereMacheta] VARCHAR (60)  NULL,
    [detalii]              XML           NULL,
    [publicabil]           INT           NULL,
    CONSTRAINT [PrincwebConfigTipuri] PRIMARY KEY CLUSTERED ([Meniu] ASC, [Tip] ASC, [Subtip] ASC, [Ordine] ASC) ON [WEB]
);


GO
--***
create trigger webconfigtipuri_tr
	on webconfigtipuri
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
insert into syssWebConfigTipuri
(user_name, host_name, program_name, tip_operatie, data_modificarii, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, publicabil, ProcInchidereMacheta, detalii)
select suser_name(), host_name(), program_name(), @delete, getdate(), Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, publicabil, ProcInchidereMacheta, detalii
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, publicabil, ProcInchidereMacheta, detalii
	from inserted