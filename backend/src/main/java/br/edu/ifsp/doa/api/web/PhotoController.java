package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.domain.DonationPhoto;
import br.edu.ifsp.doa.api.service.PhotoService;
import java.time.Duration;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Entrega os bytes da imagem. Público por design: o id é um UUID e o app carrega com Image.network. */
@RestController
@RequestMapping("/api/photos")
public class PhotoController {
    private final PhotoService photos;

    public PhotoController(PhotoService photos) {
        this.photos = photos;
    }

    @GetMapping("/{id}")
    public ResponseEntity<byte[]> get(@PathVariable String id) {
        DonationPhoto p = photos.get(id);
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(p.getContentType()))
            .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic())
            .body(p.getData());
    }
}
