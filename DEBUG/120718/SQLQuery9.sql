exec sp_executesql N'INSERT INTO TET..pozcon (Subunitate , Tip , Contract , Tert , Data , Factura , Punct_livrare , Explicatii , Cod , UM , Zi_scadenta_din_luna , Cantitate , Cant_disponibila , Pret , Discount , Cota_TVA , Suma_TVA , Numar_pozitie , Termen , Cant_aprobata , Mod_de_plata , Cant_realizata , Pret_promotional , Valuta , Utilizator , Data_operarii , Ora_operarii ) VALUES ( @P1 , @P2, @P3, @P4, @P5, @P6, @P7, @P8, @P9, @P10, @P11, @P12, @P13, @P14, @P15, @P16, @P17, @P18, @P19, @P20, @P21, @P22, @P23, @P24, @P25, @P26, @P27) ',N'@P1 char(1),@P2 char(2),@P3 char(4),@P4 char(10),@P5 datetime,@P6 char(3),@P7 varchar(1),@P8 char(50),@P9 char(11),@P10 varchar(1),@P11 smallint,@P12 float,@P13 float,@P14 float,@P15 real,@P16 real,@P17 float,@P18 int,@P19 datetime,@P20 float,@P21 char(8),@P22 float,@P23 float,@P24 varchar(1),@P25 char(6),@P26 datetime,@P27 char(6)','1','BK','6207','RO10567720','2012-07-18 00:00:00','101',' ','                                        0000/00/00','PKKP600/800',' ',0,1,0,221,0,24,53.039999999999999,3,'2012-07-01 00:00:00',1,'20120718',0,0,' ','CAPSUC','2012-07-18 00:00:00','131514'