exec sp_executesql N'--INSERT INTO TEST ..contcor (ContCG , Cont_strain , DenS , Loc_de_munca ) VALUES ( @P1 , @P2, @P3, @P4) ',N'@P1 char(4),@P2 varchar(1),@P3 varchar(1),@P4 varchar(1)','4511',' ',' ',' '
exec sp_executesql N'--INSERT INTO TEST ..decimpl (Subunitate , Tip , Decont , Data , Data_scadentei , Marca , Loc_de_munca , Comanda , Cont , Explicatii , Valoare , Decontat , Data_ultimei_decontari , Sold , Valuta , Curs , Valoare_valuta , Decontat_valuta , Sold_valuta ) VALUES ( @P1 , @P2, @P3, @P4, @P5, @P6, @P7, @P8, @P9, @P10, @P11, @P12, @P13, @P14, @P15, @P16, @P17, @P18, @P19) ',N'@P1 char(1),@P2 char(1),@P3 char(6),@P4 datetime,@P5 datetime,@P6 char(5),@P7 varchar(1),@P8 varchar(1),@P9 char(4),@P10 varchar(1),@P11 float,@P12 float,@P13 datetime,@P14 float,@P15 char(3),@P16 float,@P17 float,@P18 float,@P19 float','1','T','DEC123','2011-05-04 00:00:00','2011-05-31 00:00:00','01001',' ',' ','4511',' ',400,200,'2011-05-20 00:00:00',200,'EUR',4.5999999999999996,100,50,50
exec sp_executesql N'--INSERT INTO TEST ..deconturi (Subunitate , Tip , Decont , Data , Data_scadentei , Marca , Loc_de_munca , Cont , Valoare , Decontat , Data_ultimei_decontari , Sold , Valuta , Curs , Valoare_valuta , Decontat_valuta , Sold_valuta , Comanda , Explicatii ) VALUES ( @P1 , @P2, @P3, @P4, @P5, @P6, @P7, @P8, @P9, @P10, @P11, @P12, @P13, @P14, @P15, @P16, @P17, @P18, @P19) ',N'@P1 char(1),@P2 char(1),@P3 char(6),@P4 datetime,@P5 datetime,@P6 char(5),@P7 varchar(1),@P8 char(4),@P9 float,@P10 float,@P11 datetime,@P12 float,@P13 char(3),@P14 float,@P15 float,@P16 float,@P17 float,@P18 varchar(1),@P19 varchar(1)','1','T','DEC123','2011-05-04 00:00:00','2011-05-31 00:00:00','01001',' ','4511',400,200,'2011-05-20 00:00:00',200,'EUR',4.5999999999999996,100,50,50,' ',' '
select * from decimpl