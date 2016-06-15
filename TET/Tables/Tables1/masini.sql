CREATE TABLE [dbo].[masini] (
    [cod_masina]              CHAR (20) NOT NULL,
    [tip_masina]              CHAR (20) NOT NULL,
    [nr_inmatriculare]        CHAR (15) NOT NULL,
    [denumire]                CHAR (40) NOT NULL,
    [nr_inventar]             CHAR (13) NOT NULL,
    [capacitate_metri_cubi]   REAL      NOT NULL,
    [consum_normat_100km]     REAL      NOT NULL,
    [consum_pe_ora]           REAL      NOT NULL,
    [grupa]                   CHAR (20) NOT NULL,
    [loc_de_munca]            CHAR (9)  NOT NULL,
    [coeficient]              REAL      NOT NULL,
    [tonaj]                   REAL      NOT NULL,
    [benzina_sau_motorina]    CHAR (1)  NOT NULL,
    [capacitate_rezervor]     REAL      NOT NULL,
    [capacitate_baie_de_ulei] REAL      NOT NULL,
    [norma_de_ulei]           REAL      NOT NULL,
    [consum_vara]             REAL      NOT NULL,
    [consum_iarna]            REAL      NOT NULL,
    [consum_usor]             REAL      NOT NULL,
    [consum_mediu]            REAL      NOT NULL,
    [consum_greu]             REAL      NOT NULL,
    [km_la_bord_efectivi]     INT       NOT NULL,
    [km_la_bord_echivalenti]  INT       NOT NULL,
    [km_SU]                   INT       NOT NULL,
    [km_RK]                   INT       NOT NULL,
    [km_RT1]                  INT       NOT NULL,
    [km_RT2]                  INT       NOT NULL,
    [ultim_SU]                DATETIME  NOT NULL,
    [ultim_RK]                DATETIME  NOT NULL,
    [ultim_RT1]               DATETIME  NOT NULL,
    [ultim_RT2]               DATETIME  NOT NULL,
    [de_care_masina]          CHAR (1)  NOT NULL,
    [de_putere_mare]          CHAR (1)  NOT NULL,
    [Comanda]                 CHAR (13) NOT NULL,
    [data_expirarii_ITP]      DATETIME  NOT NULL,
    [Firma_CASCO]             CHAR (30) NOT NULL,
    [Serie_caroserie]         CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [principal]
    ON [dbo].[masini]([cod_masina] ASC);


GO
CREATE NONCLUSTERED INDEX [tip_masina]
    ON [dbo].[masini]([tip_masina] ASC);


GO
CREATE NONCLUSTERED INDEX [grupa_masina]
    ON [dbo].[masini]([grupa] ASC);


GO
--***
CREATE trigger masinisterg on masini for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssmasini  
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'A',
	cod_masina,tip_masina,nr_inmatriculare, denumire,nr_inventar,capacitate_metri_cubi, consum_normat_100km,
	consum_pe_ora, grupa,loc_de_munca, coeficient,tonaj, benzina_sau_motorina, capacitate_rezervor,
	capacitate_baie_de_ulei, norma_de_ulei, consum_vara, consum_iarna, consum_usor,consum_mediu, consum_greu,
	km_la_bord_efectivi, km_la_bord_echivalenti, km_SU,km_RK, km_RT1,km_RT2,ultim_SU,ultim_RK,ultim_RT1,
	ultim_RT2, de_care_masina, de_putere_mare, Comanda, data_expirarii_ITP, Firma_CASCO, Serie_caroserie 
from inserted   
    
insert into syssmasini  
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'S',   
cod_masina,tip_masina,nr_inmatriculare, denumire,nr_inventar,capacitate_metri_cubi, consum_normat_100km,
consum_pe_ora, grupa,loc_de_munca, coeficient,tonaj, benzina_sau_motorina, capacitate_rezervor,
capacitate_baie_de_ulei, norma_de_ulei, consum_vara, consum_iarna, consum_usor,consum_mediu, consum_greu,
km_la_bord_efectivi, km_la_bord_echivalenti, km_SU,km_RK, km_RT1,km_RT2,ultim_SU,ultim_RK,ultim_RT1,
ultim_RT2, de_care_masina, de_putere_mare, Comanda, data_expirarii_ITP, Firma_CASCO, Serie_caroserie  
from deleted  
end
