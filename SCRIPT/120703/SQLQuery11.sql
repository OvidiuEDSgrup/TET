exec sp_executesql N'UPDATE TESTOV ..pozdoc SET Comanda = @P1, Utilizator = @P2, Data_operarii = @P3, Ora_operarii = @P4 WHERE Subunitate = @P5 AND Tip = @P6 AND Numar = @P7 AND Data = @P8 AND Numar_pozitie = @P9',N'@P1 char(4),@P2 char(4),@P3 datetime,@P4 char(6),@P5 char(1),@P6 char(2),@P7 char(7),@P8 datetime,@P9 int','2755','ASIS','2012-07-03 00:00:00','123633','1','TE','9320143','2012-07-02 00:00:00',51565