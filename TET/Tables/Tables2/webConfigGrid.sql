CREATE TABLE [dbo].[webConfigGrid] (
    [Meniu]       VARCHAR (20)  NOT NULL,
    [Tip]         VARCHAR (2)   NULL,
    [Subtip]      VARCHAR (2)   NULL,
    [InPozitii]   BIT           NOT NULL,
    [NumeCol]     VARCHAR (50)  NULL,
    [DataField]   VARCHAR (50)  NULL,
    [TipObiect]   VARCHAR (50)  NULL,
    [Latime]      INT           NULL,
    [Ordine]      INT           NULL,
    [Vizibil]     BIT           NULL,
    [modificabil] BIT           NULL,
    [formula]     VARCHAR (MAX) NULL,
    [detalii]     XML           NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigGrid]
    ON [dbo].[webConfigGrid]([Meniu] ASC, [Tip] ASC, [Subtip] ASC, [DataField] ASC, [InPozitii] ASC, [Ordine] ASC)
    ON [WEB];


GO
--***
create trigger webconfiggrid_tr
	on webconfiggrid
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
insert into sysswebconfiggrid
(user_name, host_name, program_name, tip_operatie, data_modificarii, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, modificabil, formula, detalii)
select suser_name(), host_name(), program_name(), @delete, getdate(), Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, modificabil, formula, detalii
	from deleted
union all
select suser_name(), host_name(), program_name(), @insert, getdate(), Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, modificabil, formula, detalii
	from inserted