package br.edu.ifsp.doa.api.service;

import br.edu.ifsp.doa.api.domain.Donation;
import br.edu.ifsp.doa.api.domain.DonationPhoto;
import br.edu.ifsp.doa.api.domain.DonationStatus;
import br.edu.ifsp.doa.api.repository.DonationPhotoRepository;
import br.edu.ifsp.doa.api.repository.DonationRepository;
import br.edu.ifsp.doa.api.repository.DonorRepository;
import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.web.ApiException;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@Transactional
public class PhotoService {
    public static final int MAX_PHOTOS = 5;
    public static final long MAX_BYTES = 5L * 1024 * 1024;

    private final DonationPhotoRepository photos;
    private final DonationRepository donations;
    private final DonorRepository donors;

    public PhotoService(DonationPhotoRepository photos, DonationRepository donations, DonorRepository donors) {
        this.photos = photos;
        this.donations = donations;
        this.donors = donors;
    }

    /** Caminho relativo da imagem (o app junta com a URL base da API). */
    public static String urlOf(String photoId) {
        return "/api/photos/" + photoId;
    }

    @Transactional(readOnly = true)
    public List<String> urlsOf(Long donationId) {
        return photos.findIdsByDonationId(donationId).stream().map(PhotoService::urlOf).toList();
    }

    public String add(AuthUser user, Long donationId, MultipartFile file) {
        Donation d = ownedBy(user, donationId);
        if (d.getStatus() != DonationStatus.AVAILABLE) {
            throw ApiException.conflict("Só é possível alterar as fotos de uma doação disponível.");
        }
        if (photos.countByDonationId(donationId) >= MAX_PHOTOS) {
            throw ApiException.conflict("Cada doação aceita até " + MAX_PHOTOS + " fotos.");
        }
        if (file == null || file.isEmpty()) {
            throw ApiException.badRequest("Envie o arquivo da foto no campo \"file\".");
        }
        if (file.getSize() > MAX_BYTES) {
            throw ApiException.badRequest("A foto deve ter no máximo 5 MB.");
        }
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw ApiException.badRequest("Não foi possível ler a foto enviada.");
        }
        // O tipo é decidido pelo conteúdo real do arquivo, não pelo que o cliente declarou.
        String type = detectImageType(bytes);
        if (type == null) {
            throw ApiException.badRequest("Formato não suportado. Envie uma imagem JPEG, PNG ou WebP.");
        }
        DonationPhoto p = new DonationPhoto();
        p.setId(UUID.randomUUID().toString());
        p.setDonation(d);
        p.setContentType(type);
        p.setSizeBytes(bytes.length);
        p.setData(bytes);
        photos.save(p);
        return urlOf(p.getId());
    }

    public void remove(AuthUser user, Long donationId, String photoId) {
        Donation d = ownedBy(user, donationId);
        DonationPhoto p = photos.findById(photoId)
            .filter(x -> x.getDonation().getId().equals(d.getId()))
            .orElseThrow(() -> ApiException.notFound("Foto não encontrada."));
        photos.delete(p);
    }

    public void removeAllOf(Long donationId) {
        photos.deleteByDonationId(donationId);
    }

    @Transactional(readOnly = true)
    public DonationPhoto get(String photoId) {
        return photos.findById(photoId).orElseThrow(() -> ApiException.notFound("Foto não encontrada."));
    }

    private Donation ownedBy(AuthUser user, Long donationId) {
        var donor = donors.findByUserId(user.id())
            .orElseThrow(() -> ApiException.forbidden("Apenas doadores podem gerenciar fotos."));
        Donation d = donations.findById(donationId)
            .orElseThrow(() -> ApiException.notFound("Doação não encontrada."));
        if (!d.getDonor().getId().equals(donor.getId())) {
            throw ApiException.forbidden("Esta doação não é sua.");
        }
        return d;
    }

    /** Reconhece JPEG, PNG e WebP pelos primeiros bytes (assinatura do arquivo). */
    static String detectImageType(byte[] b) {
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') {
            return "image/png";
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
            && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') {
            return "image/webp";
        }
        return null;
    }
}
