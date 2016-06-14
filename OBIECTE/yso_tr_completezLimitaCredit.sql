DROP TRIGGER yso_tr_completezLimitaCredit
GO
CREATE TRIGGER yso_tr_completezLimitaCredit ON Terti 
AFTER INSERT
AS
UPDATE Terti SET Sold_maxim_ca_beneficiar=9999
WHERE Terti.Sold_maxim_ca_beneficiar=0 
	AND EXISTS (SELECT TOP (1) 1 FROM inserted I WHERE I.Subunitate=Terti.Subunitate and I.Tert=Terti.Tert)
	