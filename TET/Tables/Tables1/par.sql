CREATE TABLE [dbo].[par] (
    [Tip_parametru]      CHAR (2)   NOT NULL,
    [Parametru]          CHAR (9)   NOT NULL,
    [Denumire_parametru] CHAR (30)  NOT NULL,
    [Val_logica]         BIT        NOT NULL,
    [Val_numerica]       FLOAT (53) NOT NULL,
    [Val_alfanumerica]   CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Parametru]
    ON [dbo].[par]([Tip_parametru] ASC, [Parametru] ASC);


GO
--***
CREATE trigger paramsterg on par for update, delete  /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

if exists (select * from sysobjects where name ='fIauUtilizatorCurent')
begin
	set @Utilizator=dbo.fIauUtilizatorCurent()
	select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
	set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

	/*
		AP/POZITIE	-> wScriuAviz + ult. nr pozitie CG+, SA+
		DO/AVIZE	-> CG, CG+
		AP/POZITIE	-> proceduri RIA
		GE/MATERIAL	-> CG+ - Ultimul nr nomencl folosit
		GE/TERT	-> CG+ - Ultimul nr de tert folosit
		DO/LOCTERT	-> ?
		GE/NOMENCL	-> ultimul nr nomencl
		UC/ NRCNTFC -> ultimul nr de contract
	*/
	insert into syssp
		select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator,
		Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica 
	   from deleted	
		where tip_parametru+parametru not in ('DOPOZITIE','DOAVIZE','APPOZITIE','GEMATERIAL','GETERT','DOLOCTERT','GENOMENCL','UCNRCNTFC') -- contorizare nr pozitie
		and tip_parametru<>'ID' -- aici se pun informatii temporare pentru facturare
		and not (ISNUMERIC(Parametru)= 1 and denumire_parametru like 'permit%') -- linii scrise din ASiSplus pt. exceptare temporara in triggere
end

-- select * from syssp where tip_parametru+parametru in ('DOPOZITIE','DOAVIZE','APPOZITIE','GEMATERIAL','GETERT','DOLOCTERT','GENOMENCL','UCNRCNTFC') -- contorizare nr pozitie
-- select * from syssp where ISNUMERIC(Parametru)= 1 and denumire_parametru like 'permit%' 
-- select * from syssp where tip_parametru='iD'

-- delete syssp where tip_parametru+parametru in ('DOPOZITIE','DOAVIZE','APPOZITIE','GEMATERIAL','GETERT','DOLOCTERT','GENOMENCL','UCNRCNTFC')
-- delete syssp where ISNUMERIC(Parametru)= 1 and denumire_parametru like 'permit%' 
-- delete syssp where tip_parametru='ID'
